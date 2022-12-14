// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

locals {
  apis = ["iam.googleapis.com", "run.googleapis.com", "compute.googleapis.com", "cloudasset.googleapis.com", "sql-component.googleapis.com", "cloudapis.googleapis.com", "sqladmin.googleapis.com", "secretmanager.googleapis.com", "artifactregistry.googleapis.com"]
}

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_project_service" "project" {
  for_each = toset(local.apis)
  project  = data.google_project.project.project_id
  service  = each.key

  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "ipam" {
  provider = google-beta

  location      = var.artifact_registry_location
  project       = data.google_project.project.project_id
  repository_id = "ipam-autopilot"
  description   = "Docker repository for IPAM Autopilot"
  format        = "DOCKER"

  depends_on = [
    google_project_service.project
  ]
}

resource "google_artifact_registry_repository_iam_binding" "ipam_container_builder" {
  project    = data.google_project.project.project_id
  location   = var.artifact_registry_location
  repository = google_artifact_registry_repository.ipam.name
  role       = "roles/artifactregistry.writer"
  members    = toset(var.artifact_registry_writers)
}

resource "google_artifact_registry_repository_iam_binding" "container_consumers" {
  project    = data.google_project.project.project_id
  location   = var.artifact_registry_location
  repository = google_artifact_registry_repository.ipam.name
  role       = "roles/artifactregistry.reader"
  members    = toset(var.artifact_registry_readers)
}

resource "google_service_account" "autopilot" {
  account_id   = "ipam-autopilot"
  display_name = "Service Account for the IPAM Autopilot"
  depends_on = [
    google_project_service.project
  ]
}

resource "google_project_iam_member" "sql_client" {
  project = data.google_project.project.id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.autopilot.email}"
}

resource "google_project_iam_member" "token_creator" {
  project = data.google_project.project.id
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.autopilot.email}"
}

resource "google_organization_iam_member" "cai_viewer" {
  count  = (var.organization_id != "") && (var.disable_org_level_cai_permissions == false) ? 1 : 0
  org_id = var.organization_id
  role   = "roles/cloudasset.viewer"
  member = "serviceAccount:${google_service_account.autopilot.email}"
}

resource "google_cloud_run_service" "default" {
  provider = google-beta
  name     = "ipam-autopilot"
  location = var.region
  project  = data.google_project.project.project_id

  metadata {
    annotations = {
      "run.googleapis.com/ingress" : "all" // internal-and-cloud-load-balancing
    }
  }

  template {
    spec {
      service_account_name = google_service_account.autopilot.email
      containers {
        image = var.ipam_container_image
        ports {
          name           = "http1"
          container_port = 8080
        }
        env {
          name  = "CAI_ORG_ID"
          value = var.organization_id
        }
        env {
          name  = "DATABASE_NET"
          value = "unix"
        }
        env {
          name  = "DATABASE_NAME"
          value = google_sql_database.database.name
        }
        env {
          name  = "DATABASE_USER"
          value = google_sql_user.user.name
        }
        env {
          name  = "DISABLE_DATABASE_MIGRATION"
          value = tostring(var.disable_database_migration)
        }
        env {
          name = "DATABASE_PASSWORD"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.secret.secret_id
              key  = "latest"
            }
          }
        }
        env {
          name  = "DATABASE_HOST"
          value = "/cloudsql/${google_sql_database_instance.instance.connection_name}"
        }
      }
    }
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"      = "100"
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.instance.connection_name
        "run.googleapis.com/client-name"        = "ipam"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_project_service.project,
    google_sql_database.database,
    google_sql_user.user,
    google_secret_manager_secret_iam_member.secret-access,
    google_project_iam_member.sql_client,
    google_project_iam_member.token_creator,
    google_organization_iam_member.cai_viewer,
  ]
}

resource "google_cloud_run_service_iam_binding" "default" {
  location = google_cloud_run_service.default.location
  project  = google_cloud_run_service.default.project
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  members  = toset(var.cloudrun_service_users)
}
