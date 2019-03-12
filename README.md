
# HTPC powered by k3s

This is my current HTPC setup. It runs on [k3s](https://k3s.io/) - a lightweight and easy to install Kubernetes distribution.
It includes the following applications:

* [Sonarr](https://sonarr.tv/) for tv shows
* [Radarr](https://radarr.video/) for movies
* [Bazarr](https://github.com/morpheus65535/bazarr) for subtitles
* Transmission for torrents
* [Jackett](https://github.com/Jackett/Jackett) 
* [Emby](https://emby.media/)

## Getting Started

### Quickstart

```bash
# for x86_64
kubectl apply -f https://raw.githubusercontent.com/fabito/htk8s/v0.1/install_x86_64.yaml

#for raspberry pi (ARM)
kubectl apply -f https://raw.githubusercontent.com/fabito/htk8s/v0.1/install_armhf.yaml
```

### Verifying the installation

Once applied you should be able to reach each component ui using the links below. Don't forget to replace `localhost` by the IP or the server name running k3s.

|App|URI
|---|---
|radarr|http://localhost/radarr
|sonarr|http://localhost/sonarr
|bazarr|http://localhost/bazarr
|transmission|http://localhost/transmission
|emby|http://localhost/

Check the [ingress.yaml](base/ingress.yaml) for more details.

Each module except for Emby is configured to respond on a custom basepath (most of this configuration is done by init containers).

## How it works

It uses [LinuxServers](https://www.linuxserver.io/our-images/) images.

It uses a `hostPath` volume to store configuration and media files. It defaults to the `/htpc` directory

TODO