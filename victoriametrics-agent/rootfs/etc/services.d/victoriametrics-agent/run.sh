#!/usr/bin/with-contenv bashio
# ==============================================================================
# Start the service
# s6-overlay docs: https://github.com/just-containers/s6-overlay
# ==============================================================================

REMOTE_WRITE_URL=$(bashio::config 'remoteWrite.url')
#PROMSCRAPE_CONFIG_FILE_PATH=$(bashio::config 'promscrape.config')

bashio::log.info "Starting VictoriaMetrics vmagent with remoteWrite.url=${REMOTE_WRITE_URL}"

## Run your program
exec /vmagent-prod "-remoteWrite.url=${REMOTE_WRITE_URL}"