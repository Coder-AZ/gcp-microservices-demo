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

gcp_project_id = "ashish-project-495421"

memorystore = false

# Secrets (cloudflare_tunnel_token, datadog_api_key) are intentionally NOT set
# here. Provide them as environment variables so real values never land in a
# committed file:
#
#   export TF_VAR_cloudflare_tunnel_token=...   # required: the app's ingress
#   export TF_VAR_datadog_api_key=...           # optional: enables Datadog
#
# Copy terraform/secrets.env.example to terraform/secrets.env (gitignored), fill
# it in, and `source` it before running terraform. When a TF_VAR_ var is unset,
# the variable defaults to "" and the corresponding feature is skipped.

# Datadog site is not a secret, so it can live here. Adjust for your account
# (e.g. us5.datadoghq.com, datadoghq.eu).
datadog_site = "datadoghq.com"
