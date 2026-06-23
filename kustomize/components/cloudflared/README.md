# Expose Online Boutique through a Cloudflare Tunnel (no public IP)

This component runs [`cloudflared`](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
inside the cluster and connects the internal `frontend` Service to your
Cloudflare account over an outbound-only tunnel. Combined with the
[`non-public-frontend`](../non-public-frontend) component, the app is reachable
on your Cloudflare domain with automatic HTTPS and **no GCP public IP or
LoadBalancer**.

## How it works

- The `cloudflared` Deployment authenticates with a **tunnel token** stored in a
  Kubernetes Secret named `cloudflared` (key `tunnel-token`).
- The public hostname → internal service mapping is configured **in the
  Cloudflare Zero Trust dashboard** (remotely-managed tunnel). Point the tunnel's
  public hostname at the service URL `http://frontend:80`.

## Setup

### 1. Create the tunnel in Cloudflare

In the [Zero Trust dashboard](https://one.dash.cloudflare.com/) → **Networks →
Tunnels → Create a tunnel** (type *Cloudflared*). Name it (e.g.
`online-boutique`), then copy the **tunnel token** shown in the install step.

Under the tunnel's **Public Hostname** tab, add a hostname (e.g.
`shop.example.com`) with:

- **Service type:** `HTTP`
- **URL:** `frontend:80`

### 2. Create the Secret in the cluster

```bash
kubectl create secret generic cloudflared \
  --from-literal=tunnel-token='<YOUR_TUNNEL_TOKEN>' \
  -n default
```

> If you deploy with the bundled Terraform, set `cloudflare_tunnel_token` in
> `terraform/terraform.tfvars` instead and the Secret is created for you.

### 3. Enable the component

From the `kustomize/` folder:

```bash
kustomize edit add component components/cloudflared
kustomize edit add component components/non-public-frontend
```

or add both to `kustomize/kustomization.yaml` directly (already done in this
repo). Then render/apply:

```bash
kubectl apply -k .
```

## Notes

- `replicas: 2` runs two tunnel connectors for high availability. Set to `1` to
  minimize Autopilot cost for short-lived demos.
- The token is all `cloudflared` needs — no config file or credentials volume.
- Rotating the token: update the Secret and restart the Deployment
  (`kubectl rollout restart deploy/cloudflared`).
