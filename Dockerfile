# builder image
FROM container-registry.oracle.com/os/oraclelinux:7.8 as builder

ARG VERSION

# Install golang via Oracle's yum servers
RUN yum update -y \
    && yum-config-manager --save --setopt=ol7_ociyum_config.skip_if_unavailable=true \
    && yum install -y oracle-golang-release-el7 \
    && yum-config-manager --enable ol7_developer_golang113 \
    && yum-config-manager --add-repo http://yum.oracle.com/repo/OracleLinux/OL7/developer/golang113/x86_64 \
    && yum install -y git gcc make golang-1.13.3-1.el7.x86_64 \
    && yum clean all \
    && go version

# Compile to /usr/bin
ENV GOBIN=/usr/bin

# Set go path
ENV GOPATH=/go

WORKDIR /sigs.k8s.io/external-dns

COPY . .
RUN go mod vendor && \
    make test && \
    make build

# final image
FROM container-registry.oracle.com/os/oraclelinux:7-slim

COPY --from=builder /sigs.k8s.io/external-dns/build/external-dns /bin/external-dns

# COPY LICENSE and README files to the image
COPY LICENSE README.md THIRD_PARTY_LICENSES.txt /license/

# Run as UID for nobody since k8s pod securityContext runAsNonRoot can't resolve the user ID:
# https://github.com/kubernetes/kubernetes/issues/40958
USER 65534

ENTRYPOINT ["/bin/external-dns"]

