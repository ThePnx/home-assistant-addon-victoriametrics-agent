# VictoriaMetrics Agent Addon for Home Assistant

[![Open your Home Assistant instance and show the add app repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FThePnx%2Fhome-assistant-addon-victoriametrics-agent)

This add-on runs [vmagent](https://docs.victoriametrics.com/victoriametrics/vmagent/), the metrics agent of
VictoriaMetrics, next to Home Assistant. It accepts metrics from Home Assistant and sends them to an
**external** [VictoriaMetrics](https://docs.victoriametrics.com/victoriametrics/single-server-victoriametrics/)
database.

Supported architectures: `aarch64`, `amd64`, `armhf`, `armv7`, `i386`.

## What it does

- Listens on port `8429` and accepts data in every push format vmagent supports, including the InfluxDB line
  protocol (`/write`, `/api/v2/write`). So the built-in
  [InfluxDB integration](https://www.home-assistant.io/integrations/influxdb/) of Home Assistant can send every
  state change to the add-on, with no custom component.
- Forwards the data to the VictoriaMetrics URL you configure (`remoteWrite.url`).
- When VictoriaMetrics is down, keeps the data in an on-disk queue in `/data` and sends it when the database is
  back. The queue survives add-on restarts and updates.
- Shows its own metrics at `http://<home-assistant-host>:8429/metrics` (the **Open Web UI** button).

```
Home Assistant --(InfluxDB integration)--> vmagent add-on :8429 --(remote write)--> VictoriaMetrics :8428 --> Grafana
                                                 |
                                                 +-- on-disk queue in /data while VictoriaMetrics is unreachable
```

## Why vmagent and an external VictoriaMetrics

**Why VictoriaMetrics**

- Low RAM, CPU and disk use with strong compression, so it runs well on a small server or NAS
  ([features](https://docs.victoriametrics.com/victoriametrics/single-server-victoriametrics/#prominent-features)).
- Accepts the InfluxDB line protocol and the Prometheus protocols, and works as a Prometheus data source in Grafana.

**Why an agent between Home Assistant and the database**

- No data loss during outages: if the database is unreachable, vmagent buffers the data on disk
  (`remoteWrite.tmpDataPath`) and delivers it later. Home Assistant's InfluxDB integration only keeps a short
  in-memory backlog (about 30 seconds plus retries) and then drops events.
- Home Assistant always writes to an endpoint on the same machine, so a slow or remote database does not hold it up.
- Less network traffic: with a VictoriaMetrics target, vmagent uses the compressed
  [VictoriaMetrics remote write protocol](https://docs.victoriametrics.com/victoriametrics/vmagent/#victoriametrics-remote-write-protocol).
- Optional authentication and TLS towards the database, and on the add-on's own port.

## Installation

You need a running VictoriaMetrics instance that the Home Assistant machine can reach (default port `8428`). See
the [VictoriaMetrics quick start](https://docs.victoriametrics.com/victoriametrics/quick-start/).

### 1. Add the repository to Home Assistant

Click the badge at the top of this page, or add the repository by hand:

1. In Home Assistant go to **Settings** > **Apps** and select **Install app**
   (older versions: **Settings** > **Add-ons** > **Add-on Store**).
2. In the top-right menu (⋮) select **Repositories**.
3. Enter `https://github.com/ThePnx/home-assistant-addon-victoriametrics-agent` and select **Add**.
4. Close the dialog. The add-on is listed in the section **Home Assistant Addon VictoriaMetrics Agent**
   (reload the page if it does not show up).

### 2. Install and start the add-on

1. Open **VictoriaMetrics Agent Addon for Home Assistant** and select **Install**. The image is built on your
   device, so the first install takes a few minutes.
2. On the **Configuration** tab set `remoteWrite.url` to your database, for example
   `http://victoriametrics.local:8428/api/v1/write`. The default value is a placeholder and does not work.
3. Save, go back to the **Info** tab and select **Start**. Optionally enable **Start on boot** and **Watchdog**.
4. Check the **Log** tab for `fatal` errors.

### 3. Send Home Assistant data to the add-on

Add the [InfluxDB integration](https://www.home-assistant.io/integrations/influxdb/)
(**Settings** > **Devices & services** > **Add integration** > **InfluxDB**), choose **InfluxDB 1.x** and enter:

| Field               | Value |
|---------------------|-------|
| URL                 | `http://<home-assistant-host>:8429` |
| Database            | any name, e.g. `home_assistant` (stored as the `db` label) |
| Username / Password | empty, or the `httpAuth` credentials if you enabled them |

Entity filters (`include` / `exclude`), `measurement_attr` and `tags` are set in YAML, see the integration docs.
A measurement `M` with field `value` becomes the metric `M_value` in VictoriaMetrics, and tags such as
`entity_id` become labels.

## Configuration

Options are set on the add-on's **Configuration** tab. Empty optional values are not passed to vmagent, so
vmagent's own default applies. Flag details:
[vmagent command-line flags](https://docs.victoriametrics.com/victoriametrics/vmagent/#advanced-usage).

Example:

```yaml
log_level: info
remoteWrite:
  url: "http://victoriametrics.local:8428/api/v1/write"
  authenticationEnabled: false
  tmpDataPath: "/data/vmagent-remotewrite-data"
  maxDiskUsagePerURL: "100MB"
promscrape:
  enabled: false
httpAuth:
  enabled: false
tls:
  enabled: false
```

Files given by path must be visible inside the container. The add-on can read Home Assistant's `/ssl` folder
(read-only) and its own `/data` folder, so put certificates and password files in `/ssl`.

### General

| Option      | Default | Description |
|-------------|---------|-------------|
| `log_level` | `info`  | Log level of the add-on's start script: `trace`, `debug`, `info`, `notice`, `warning`, `error`, `fatal`. `debug` logs the flags passed to vmagent (passwords and tokens are masked). It does not change vmagent's own log level. |

### `remoteWrite`: where the data goes

| Option                  | Default | Description |
|-------------------------|---------|-------------|
| `url`                   | placeholder | **Required.** Remote write endpoint, e.g. `http://<host>:8428/api/v1/write` for single-node VictoriaMetrics. Any storage that supports Prometheus remote write works. |
| `authenticationEnabled` | `false` | Switch for all auth **and TLS** options below (up to `tlsServerName`). While `false`, they are ignored. |
| `basicAuthUsername`     | empty   | Basic auth username. |
| `basicAuthPassword`     | empty   | Basic auth password. |
| `basicAuthPasswordFile` | empty   | Path to a file with the basic auth password, re-read every second. Use instead of `basicAuthPassword`. |
| `bearerToken`           | empty   | Bearer token. |
| `bearerTokenFile`       | empty   | Path to a file with the bearer token, re-read every second. |
| `tlsCAFile`             | empty   | CA file used to verify the server's certificate (default: system CAs), e.g. `/ssl/ca.pem`. |
| `tlsCertFile`           | empty   | Client certificate for mutual TLS. |
| `tlsKeyFile`            | empty   | Key of the client certificate. |
| `tlsInsecureSkipVerify` | empty   | `true` skips verification of the server's certificate. Only for testing. |
| `tlsServerName`         | empty   | Server name for TLS verification, if it differs from the host in `url`. |
| `tmpDataPath`           | `/data/vmagent-remotewrite-data` | Directory of the on-disk queue for data not sent yet. Keep it under `/data`: anything else is lost on restart or update. Empty means this default. |
| `maxDiskUsagePerURL`    | `500MB` | Size limit of the queue; when it is full, the oldest data is dropped. Suffixes `KB`, `MB`, `GB`, `TB`, `KiB` ... `TiB`. `0` means unlimited. vmagent stores the queue in ~500MB chunks, so use multiples of `500MB`. |
| `vmProtoCompressLevel`  | empty   | Compression level of the VictoriaMetrics remote write protocol. Higher values send less data but use more CPU; negative values use less CPU but send more data. |

### `promscrape`: scrape Prometheus targets

| Option               | Default | Description |
|----------------------|---------|-------------|
| `enabled`            | `false` | Let vmagent scrape targets listed in a Prometheus config file. |
| `config`             | `/path/to/prometheus.yml` | Path (e.g. `/ssl/prometheus.yml`) or HTTP URL of the [scrape config](https://docs.victoriametrics.com/victoriametrics/sd_configs/). |
| `config.strictParse` | `true`  | `false` makes vmagent ignore [unsupported sections](https://docs.victoriametrics.com/victoriametrics/vmagent/#unsupported-prometheus-config-sections) instead of failing. |

> [!WARNING]
> Known issue: with `promscrape.enabled: true` the add-on does not pass `remoteWrite.url` to vmagent, so vmagent
> does not start (`at least one -remoteWrite.url command-line flag must be set`). Keep it `false` until this is fixed.

### `httpAuth`: protect the add-on's port

| Option     | Default | Description |
|------------|---------|-------------|
| `enabled`  | `false` | Require basic auth for every request to port `8429`, including `/write` and `/metrics`. |
| `username` | empty   | Username. |
| `password` | empty   | Password. |

When enabled, enter the same username and password in the InfluxDB integration.

### `httpListenAddr`: the add-on's listener

| Option             | Default | Description |
|--------------------|---------|-------------|
| `tcp`              | empty (`:8429`) | Address vmagent listens on inside the container. The add-on publishes container port `8429`, so leave it empty unless you have a reason to change it. |
| `useProxyProtocol` | empty   | `true` expects the [PROXY protocol](https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt), only behind a proxy such as HAProxy. The `/metrics` page is then not served. |

### `tls`: HTTPS on the add-on's port

| Option       | Default | Description |
|--------------|---------|-------------|
| `enabled`    | `false` | Serve port `8429` over HTTPS. Then use `https://` in the InfluxDB integration. |
| `certFile`   | empty   | Certificate, e.g. `/ssl/fullchain.pem`. Required when enabled. |
| `keyFile`    | empty   | Private key, e.g. `/ssl/privkey.pem`. Required when enabled. |
| `minVersion` | `TLS13` | Minimum TLS version: `TLS10`, `TLS11`, `TLS12`, `TLS13`. |

## Ports

| Port       | Description |
|------------|-------------|
| `8429/tcp` | vmagent HTTP API: data ingestion (`/write`, `/api/v1/import`, ...) and `/metrics`. |

## Changelog and license

See [CHANGELOG.md](victoriametrics-agent/CHANGELOG.md). Licensed under the [MIT license](LICENSE).
