
# HTPC powered by k3s

[k3s](https://k3s.io/) is a lightweight and easy to install Kubernetes distribution

It uses [LinuxServers](https://www.linuxserver.io/our-images/) images to setup a HTPC 

* Sonarr
* Radarr
* Transmission
* Jackett
* Emby

I uses a `hostPath` volume to store configuration files and media. It defaults to `/htpc`

### Requirements

* k3s
* kubectl
* kustomize


### Installation instructions

Install k3s and verify

Create the `htpc` namespace.

```bash
kubectl create -n htpc
```

Use Kustomize to create the resources:


```bash
# for x86_64
kustomize build overlays/x86 | kubectl apply -f -

#for raspberry pi (ARM)
kustomize build overlays/armhf | kubectl apply -f -
```

### Verifying the installation

Once applied you should be 

