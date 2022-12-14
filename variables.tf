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
variable "organization_id" {
  description = "Organization ID, required for accessing CAI"
  default     = ""
}

variable "region" {
  default = "us-central1"
}

variable "artifact_registry_location" {
  default = "us"
}

variable "artifact_registry_writers" {
  description = "List of members allowed to push container images to Artifact Registry"
  default     = []
}

variable "artifact_registry_readers" {
  description = "List of users allowed to pull container images from Artifact Registry"
  default     = ["allUsers"]
}

variable "cloudrun_service_users" {
  description = "List of members allowed to execute IPAM Autopilot service on Cloud Run"
  default     = []
}

variable "container_version" {
  default = "2"
}

variable "project_id" {
}

variable "disable_database_migration" {
  default = false
}

variable "disable_org_level_cai_permissions" {
  description = "If true, skip permissions grant on the org level (roles/cloudasset.viewer)"
  default     = false
}

variable "ipam_container_image" {
  default     = "us-docker.pkg.dev/ox-ipam-autopilot/ipam-autopilot/ipam-autopilot:latest"
  description = "Override container image used by Cloud Run"
}
