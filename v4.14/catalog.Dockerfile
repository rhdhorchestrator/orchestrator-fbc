

# The base image is expected to contain /bin/opm (with a serve subcommand) and /bin/grpc_health_probe
FROM registry.redhat.io/openshift4/ose-operator-registry:v4.14 as builder

ARG BUNDLE=quay.io/redhat-user-workloads/orchestrator-releng-tenant/helm-operator/operator-bundle@sha256:df0eedcaf9ed8b7c9891934d2013e81acbd02759d7c70321f2e51f375735008d
ARG CONTROLLER=controller:latest

RUN echo CONTROLLER=$CONTROLLER
RUN echo BUNDLE=$BUNDLE
WORKDIR /tmp
COPY . .
USER 0
# Need to be able to update the files with sed and they're mounted as owned by root, so we become root for this sed command only
RUN echo find . -type f -name "*.yaml" -exec sed -i 's#controller:latest#'$CONTROLLER'#; s#bundle:latest#'$BUNDLE'#' {} +

FROM registry.redhat.io/openshift4/ose-operator-registry:v4.14

ENTRYPOINT ["/bin/opm"]
CMD ["serve", "/configs", "--cache-dir=/tmp/cache"]

COPY --from=builder /tmp/catalog/ /configs
RUN find /configs -type f -name "*.yaml" -exec cat {} +
RUN ["/bin/opm", "serve", "/configs", "--cache-dir=/tmp/cache", "--cache-only"]

# Core bundle labels.

LABEL operators.operatorframework.io.bundle.mediatype.v1=registry+v1
LABEL operators.operatorframework.io.bundle.manifests.v1=manifests/
LABEL operators.operatorframework.io.bundle.metadata.v1=metadata/
LABEL operators.operatorframework.io.bundle.package.v1=orchestrator-operator
LABEL operators.operatorframework.io.bundle.channels.v1=alpha
LABEL operators.operatorframework.io.metrics.builder=operator-sdk-v1.33.1
LABEL operators.operatorframework.io.metrics.mediatype.v1=metrics+v1
LABEL operators.operatorframework.io.metrics.project_layout=go.kubebuilder.io/v3
LABEL operators.operatorframework.io.index.configs.v1=/configs
