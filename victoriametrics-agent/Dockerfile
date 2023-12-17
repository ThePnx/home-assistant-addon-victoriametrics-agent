ARG VMAGENT_IMAGE
ARG BUILD_FROM
ARG VICOTRIAMETRICS_AGENT_VERSION

FROM $VMAGENT_IMAGE as vmagent

FROM $BUILD_FROM

COPY rootfs /
COPY --from=vmagent /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
EXPOSE 8429
ENTRYPOINT ["/vmagent-prod"]
COPY ./vmagent-prod ./vmagent-prod
