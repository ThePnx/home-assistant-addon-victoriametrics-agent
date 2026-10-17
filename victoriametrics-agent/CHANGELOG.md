# Changelog

## 0.2
- vmagent v1.96.0 -> v1.154.0 (`victoriametrics/vmagent` image): almost 3 years of fixes, see
  https://docs.victoriametrics.com/changelog/. Every flag the add-on passes still exists in v1.154.0.
- Base image `ghcr.io/home-assistant/*-base` 3.19 -> 3.21 (Alpine 3.21, s6-overlay 3.2.2.0). The bashio functions
  the run script uses are unchanged.
- The remote-write queue now defaults to `/data/vmagent-remotewrite-data`. Before, an empty `remoteWrite.tmpDataPath`
  left it inside the container, so a restart or update dropped every sample not yet sent. A path you set is kept.
- `tls.certFile` / `tls.keyFile` default to empty instead of `/path/to/...` placeholders. Existing installs keep
  their saved values.

## 0.1
- First version: vmagent v1.96.0 on base 3.19.
