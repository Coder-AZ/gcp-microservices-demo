# Copyright 2024 Bridge IT Consulting
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

# Optional Datadog Agent install via the official Helm chart (Autopilot-aware).
# Enabled only when var.datadog_api_key is set. Requires the `helm` CLI locally.
# The API key is provided through the `datadog-secret` Secret created in main.tf.
resource "null_resource" "datadog_agent" {
  count = var.datadog_api_key != "" ? 1 : 0

  triggers = {
    namespace = var.namespace
    site      = var.datadog_site
    values    = filesha256("${path.module}/../datadog/values-autopilot.yaml")
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-exc"]
    command     = <<-EOT
    helm repo add datadog https://helm.datadoghq.com
    helm repo update
    helm upgrade --install datadog datadog/datadog \
      --namespace ${var.namespace} \
      -f ${path.module}/../datadog/values-autopilot.yaml \
      --set datadog.site=${var.datadog_site}
    EOT
  }

  depends_on = [
    module.gcloud,
    null_resource.datadog_secret
  ]
}
