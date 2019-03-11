
# HTPC powered by k3s

[k3s](https://k3s.io/) is a lightweight and easy to install Kubernetes distribution

It uses [LinuxServers](https://www.linuxserver.io/our-images/) images to setup an HTPC 

* Sonarr for tv shows
* Radarr for movies
* Bazarr for subtitles
* Transmission for torrents
* Jackett 
* Emby

It uses a `hostPath` volume to store configuration and media files. It defaults to `/htpc`

### Requirements

* k3s
* kubectl
* kustomize


### Installation instructions

Install k3s and verify

Use Kustomize to create the resources:

```bash
# for x86_64
kustomize build overlays/x86 | kubectl apply -f -

#for raspberry pi (ARM)
kustomize build overlays/armhf | kubectl apply -f -
```

### Verifying the installation

Once applied you should be 
You should be able to reach each component:

|App|URI
|---|---
|radarr|http://localhost/radarr
|sonarr|http://localhost/sonarr
|bazarr|http://localhost/bazarr
|transmission|http://localhost/transmission
|emby|http://localhost/

Check the [ingress.yaml](base/ingress.yaml) for more details.

Each module except for Emby is configured to respond on a custom basepath (most of this configuration is done by init containers).