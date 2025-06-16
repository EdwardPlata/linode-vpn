FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    openvpn \
    easy-rsa \
    iptables \
    curl \
    wget \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /etc/openvpn/easy-rsa \
    && mkdir -p /etc/openvpn/keys \
    && mkdir -p /etc/openvpn/ccd \
    && mkdir -p /var/log/openvpn

# Copy Easy-RSA files
RUN cp -r /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/

# Set working directory
WORKDIR /etc/openvpn/easy-rsa

# Copy configuration files and scripts
COPY config/vars /etc/openvpn/easy-rsa/vars
COPY config/server.conf /etc/openvpn/server.conf
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY generate-client.sh /usr/local/bin/generate-client.sh

# Make scripts executable
RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/generate-client.sh

# Expose OpenVPN port
EXPOSE 1194/udp

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD pgrep openvpn || exit 1

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
