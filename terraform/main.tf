# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Definition of local variables
locals {
  base_apis = [
    "container.googleapis.com",
    "monitoring.googleapis.com",
    "cloudtrace.googleapis.com",
    "cloudprofiler.googleapis.com"
  ]
  memorystore_apis = ["redis.googleapis.com"]
  cluster_name     = google_container_cluster.my_cluster.name
}

# Enable Google Cloud APIs
module "enable_google_apis" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 18.0"

  project_id                  = var.gcp_project_id
  disable_services_on_destroy = false

  # activate_apis is the set of base_apis and the APIs required by user-configured deployment options
  activate_apis = concat(local.base_apis, var.memorystore ? local.memorystore_apis : [])
}

# Create GKE cluster
resource "google_container_cluster" "my_cluster" {

  name     = var.name
  location = var.region

  # Enable autopilot for this cluster
  enable_autopilot = true

  # Set an empty ip_allocation_policy to allow autopilot cluster to spin up correctly
  ip_allocation_policy {
  }

  # Demo workflow: this cluster is meant to be created for a demo and destroyed
  # afterwards, so deletion protection is disabled to allow `terraform destroy`.
  # Set back to true (or remove) for any long-lived/production cluster.
  deletion_protection = false

  depends_on = [
    module.enable_google_apis
  ]
}

# Get credentials for cluster
module "gcloud" {
  source  = "terraform-google-modules/gcloud/google"
  version = "~> 4.0"

  platform              = "linux"
  additional_components = ["kubectl", "beta"]

  create_cmd_entrypoint = "gcloud"
  # Module does not support explicit dependency
  # Enforce implicit dependency through use of local variable
  create_cmd_body = "container clusters get-credentials ${local.cluster_name} --zone=${var.region} --project=${var.gcp_project_id}"
}

# Create the Secret consumed by the cloudflared tunnel Deployment.
# Idempotent: re-applies the Secret on every run. Skipped when no token is set.
resource "null_resource" "cloudflared_secret" {
  count = var.cloudflare_tunnel_token != "" ? 1 : 0

  triggers = {
    token_sha = sha256(var.cloudflare_tunnel_token)
    namespace = var.namespace
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = <<-EOT
    kubectl create secret generic cloudflared \
      --from-literal=tunnel-token='${var.cloudflare_tunnel_token}' \
      -n ${var.namespace} \
      --dry-run=client -o yaml | kubectl apply -f -
    EOT
  }

  depends_on = [
    module.gcloud
  ]
}

# Create the Secret consumed by the Datadog Agent (see datadog.tf).
# Idempotent. Skipped when no API key is set.
resource "null_resource" "datadog_secret" {
  count = var.datadog_api_key != "" ? 1 : 0

  triggers = {
    key_sha   = sha256(var.datadog_api_key)
    namespace = var.namespace
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = <<-EOT
    kubectl create secret generic datadog-secret \
      --from-literal=api-key='${var.datadog_api_key}' \
      -n ${var.namespace} \
      --dry-run=client -o yaml | kubectl apply -f -
    EOT
  }

  depends_on = [
    module.gcloud
  ]
}

# Apply YAML kubernetes-manifest configurations
resource "null_resource" "apply_deployment" {
  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = "kubectl apply -k ${var.filepath_manifest} -n ${var.namespace}"
  }

  depends_on = [
    module.gcloud,
    null_resource.cloudflared_secret,
    null_resource.datadog_secret
  ]
}

# Wait condition for all Pods to be ready before finishing
resource "null_resource" "wait_conditions" {
  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = <<-EOT
    kubectl wait --for=condition=AVAILABLE apiservice/v1beta1.metrics.k8s.io --timeout=180s
    kubectl wait --for=condition=ready pods --all -n ${var.namespace} --timeout=280s
    EOT
  }

  depends_on = [
    resource.null_resource.apply_deployment
  ]
}
