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

# Cloudflare Tunnel token. Required to reach the app, since the public frontend
# LoadBalancer is disabled (internal-only). Leave empty to deploy without ingress.
# Treat as a secret — do not commit a real value.
cloudflare_tunnel_token = ""

# Datadog. Set the API key to install the Datadog Agent (requires `helm` CLI).
# Leave empty to skip Datadog. Treat as a secret — do not commit a real value.
datadog_api_key = ""
datadog_site    = "datadoghq.com"
