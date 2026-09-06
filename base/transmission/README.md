# Configuring Transmission on k3s

Transmission has two configuration layers:

- **Kubernetes manifests** control the image, environment, storage mounts and network exposure.
- **Transmission settings** live in `/config/settings.json`. This repo mounts `/config` from the `transmission` subdirectory of the shared hostPath volume (default: `/opt/htpc/transmission`). Torrent-specific settings are stored in `/config/resume`.

The Web UI and `transmission-remote` communicate with the running daemon over RPC. Use them for runtime settings; do not mount a read-only ConfigMap over the entire settings file, since Transmission needs to write it.

## Stable incoming peer port

The deployment sets `PEERPORT=51413`. The LinuxServer image uses this to set the listening port and disable random-port-on-start each time the container starts. Keep this value, both container ports and both Service peer ports in sync if you change it.

The Service is a `LoadBalancer`. With the default k3s ServiceLB enabled and the node ports available, this exposes TCP and UDP port 51413 on the node. Merely declaring `containerPort` does **not** expose a port outside the cluster. Other Kubernetes distributions may require a load balancer implementation or a different exposure method.

For a node behind a router, configure:

```text
WAN TCP 51413 → <node-LAN-address>:51413
WAN UDP 51413 → <node-LAN-address>:51413
```

Reserve a stable LAN address for the node and allow these ports through any host firewall. Transmission's UPnP/NAT-PMP setting is not a substitute for Kubernetes Service exposure and a router rule when the daemon runs on a pod network.

**Forward only the peer port.** The Service also exposes Web UI/RPC port 9091 to preserve direct LAN access. This repo does not enable RPC authentication by default. Keep 9091 and its allocated NodePort on a trusted network, and do not expose the Web UI/HTTP ingress or Kubernetes API to the internet. BitTorrent peer traffic does not use the HTTP ingress route.

### Deploy and verify

Use a kubeconfig for the intended home cluster, not an unrelated current context. On a k3s host, a separately provisioned user kubeconfig may need to be selected explicitly:

```bash
export KUBECONFIG="$HOME/.kube/config"
kubectl config current-context
kubectl get nodes -o wide
```

For GitOps installations, sync through Argo CD once the manifest changes are available in its configured source. Manual edits to managed resources can be overwritten by a later sync.

For a manual installation, run from a checkout of this repo using the appropriate overlay:

```bash
kubectl diff -k overlays/x86
# Review first: this applies the whole overlay, not only Transmission.
kubectl apply -k overlays/x86
kubectl -n htpc rollout status deployment/transmission --timeout=180s
```

Deployment updates use `Recreate`: there is a brief interruption, but the old daemon exits before another pod can write to the same config directory.

Check the runtime port, Service and load balancer pods:

```bash
kubectl -n htpc exec deploy/transmission -c transmission -- \
  transmission-remote --session-info
kubectl -n htpc get svc transmission -o wide
kubectl -n kube-system get pods -o wide | grep svclb-transmission
```

The daemon's listen port should be **51413**. From another LAN device, test TCP reachability with `nc -vz <node-LAN-address> 51413`. Then, after configuring the router, request an external TCP check:

```bash
kubectl -n htpc exec deploy/transmission -c transmission -- \
  transmission-remote --port-test
```

A successful LAN connection alone does not prove internet reachability, and a TCP test does not verify UDP. If the external test fails, check the router rule, host firewall, double NAT, ISP CGNAT and any VPN routing. A VPN needs incoming port forwarding at the VPN endpoint; a home-router rule alone cannot open that path. The port-test service can also be unavailable.

## Seeding policy for selected torrents

Ratio and idle-time limits can stop a completed torrent even when the seed queue is unlimited. To allow selected torrents to seed indefinitely **without changing global defaults or other torrents**, first find their IDs:

```bash
kubectl -n htpc exec deploy/transmission -c transmission -- \
  transmission-remote --list
```

Set `TORRENT_ID` to the selected torrent's numeric ID, then apply per-torrent overrides:

```bash
TORRENT_ID=123  # Example only: replace with the ID from your own instance.
kubectl -n htpc exec deploy/transmission -c transmission -- \
  transmission-remote --torrent "$TORRENT_ID" \
  --no-seedratio --no-idle-seeding-limit
kubectl -n htpc exec deploy/transmission -c transmission -- \
  transmission-remote --torrent "$TORRENT_ID" --info
```

Disabling limits does not resume an already stopped torrent. If you want it running, start just that torrent (an incomplete torrent will resume downloading):

```bash
kubectl -n htpc exec deploy/transmission -c transmission -- \
  transmission-remote --torrent "$TORRENT_ID" --start
```

Do not use `--torrent all` unless you intend to affect every torrent. These overrides persist with the torrent's resume state, but do not automatically apply to future additions. Repeat for newly added torrents as needed. Automation clients can also override torrent policies; check their seeding and completed-download handling settings if the policy changes unexpectedly.

To return that torrent to the existing global defaults:

```bash
kubectl -n htpc exec deploy/transmission -c transmission -- \
  transmission-remote --torrent "$TORRENT_ID" \
  --seedratio-default --default-idle-seeding-limit
```

If RPC authentication is enabled, the commands need authentication too. Use Transmission's `--netrc` support with a protected file available inside the container; never put credentials or tracker URLs in this repo.

## Queues and bandwidth

- `download-queue-size` limits concurrent downloads when `download-queue-enabled` is true. Increase gradually only when the connection, disk and peers can support more active transfers.
- `seed-queue-enabled=false` disables the seed queue cap; increasing `seed-queue-size` then has no effect. Ratio limits, idle-time limits and manually stopped torrents still apply.
- More active transfers do **not** fix a closed incoming port.
- Measure bandwidth with other traffic paused before choosing speed limits. Do not copy example rates from another connection. A reasonable starting upload cap is about 80–90% of measured upload capacity, then adjust based on latency and actual usage. Transmission CLI speed limits use **kB/s**, not Mbps: `Mbps × 1000 / 8 × 0.85` gives an approximate 85% cap. Download limits depend on how much capacity you want to reserve for other uses.
- Check alternate-speed mode and its schedule if observed limits differ from the normal limits.

The manifests deliberately do not impose queue sizes, speed limits or a global seeding policy.

## Safe settings-file edits and backups

Prefer RPC/Web UI changes while the daemon is running. Editing `settings.json` in place while Transmission is running can be ignored or overwritten during shutdown.

For settings that require an offline file edit:

1. Coordinate with GitOps reconciliation if enabled, record the deployment's replica count, and stop the deployment.
2. Wait until its pod has fully terminated.
3. On the storage node, make a private backup of the **entire config directory**, including `settings.json`, `torrents` and `resume`. Backups contain sensitive RPC and tracker data; keep them out of version control.
4. Edit only the required keys in `settings.json`, validate the JSON, and preserve file ownership and permissions.
5. Restore the replica count, wait for rollout completion, and verify via RPC. Environment-managed settings such as `PEERPORT` take precedence at startup.

To recover, stop the daemon again before restoring the backup. Do not restore an older settings file over a running daemon.
