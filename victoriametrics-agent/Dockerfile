ARG VMAGENT_IMAGE
ARG BUILD_FROM
ARG VICOTRIAMETRICS_AGENT_VERSION

FROM $VMAGENT_IMAGE as vmagent

FROM $BUILD_FROM

COPY rootfs /
COPY --from=vmagent /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=vmagent ./vmagent-prod ./vmagent-prod

EXPOSE 8429

RUN chmod +x /etc/services.d/*/run
RUN chmod +x /etc/services.d/*/finish

