FROM registry.redhat.io/ubi9/skopeo:9.4 as skopeo

WORKDIR /fbc
COPY . .

ARG bundle=quay.io/redhat-user-workloads/orchestrator-releng-tenant/helm-operator/operator-bundle@sha256:df0eedcaf9ed8b7c9891934d2013e81acbd02759d7c70321f2e51f375735008d

RUN controller=$(skopeo inspect --format "{{ .Labels.controller }}" docker://${bundle}) && \
    find . -type f -name "*.yaml" -exec sed -i 's#controller:latest#'$controller'#; s#bundle:latest#'$bundle'#' {} +

# The base image is expected to contain /bin/opm (with a serve subcommand) and /bin/grpc_health_probe
FROM registry.redhat.io/openshift4/ose-operator-registry:v4.14

ENTRYPOINT ["/bin/opm"]
CMD ["serve", "/configs", "--cache-dir=/tmp/cache"]

COPY --from=skopeo /fbc/catalog /configs
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
