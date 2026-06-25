# Datadog monitoring for Online Boutique (GKE Autopilot)

This deploys the Datadog Agent to monitor the app and ship metrics, logs, and
APM traces to your Datadog account. It uses the **official Datadog Helm chart**
with [GKE Autopilot](https://docs.datadoghq.com/containers/kubernetes/installation/?tab=helm#gke-autopilot)
settings, because Autopilot restricts the privileged DaemonSets that a manual
install would need.

Values live in [`values-autopilot.yaml`](./values-autopilot.yaml).

## Prerequisites

- `helm` CLI installed
- A Datadog **API key** (Datadog → Organization Settings → API Keys)
- Cluster credentials (`gcloud container clusters get-credentials ...`)

## Install

### 1. Create the API key Secret

```bash
kubectl create secret generic datadog-secret \
  --from-literal=api-key='<YOUR_DATADOG_API_KEY>' \
  -n default
```

> If you deploy with the bundled Terraform, export `TF_VAR_datadog_api_key`
> (see `terraform/secrets.env.example`) instead and both the Secret and the Helm
> release are created for you (see `terraform/datadog.tf`).

### 2. Install the chart

```bash
helm repo add datadog https://helm.datadoghq.com
helm repo update

helm upgrade --install datadog datadog/datadog \
  --namespace default \
  -f values-autopilot.yaml \
  --set datadog.site=datadoghq.com   # change to your Datadog site if needed
```

### 3. Verify

```bash
kubectl get pods -l app.kubernetes.io/name=datadog
```

Within a few minutes the cluster, its workloads, and Online Boutique's traffic
appear in the Datadog **Containers**, **Logs**, and **APM** views.

## Uninstall

```bash
helm uninstall datadog -n default
kubectl delete secret datadog-secret -n default
```

## Notes

- Autopilot bills the agent pods' resource requests like any other workload, so
  Datadog adds a small ongoing cost while the cluster is up. Uninstall (or just
  `terraform destroy` the whole cluster) when the demo is done.
- To capture APM traces from the Go/Java/Python/Node services you'd also add the
  Datadog tracing libraries to each service; the agent above already collects
  infra metrics and container logs out of the box.
