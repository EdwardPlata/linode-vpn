# Linode OpenVPN + Pi-hole VPN Technical Documentation

## Overview

This project deploys a secure OpenVPN server with integrated Pi-hole ad-blocking on Linode infrastructure using Terraform for Infrastructure as Code (IaC). The solution provides a personal VPN service that encrypts internet traffic, protects privacy, blocks ads and trackers, and allows secure access to remote networks.

## Architecture

### Infrastructure Components

1. **Linode Compute Instance**
   - Type: g6-nanode-1 (1GB RAM, 1 CPU core)
   - Operating System: Ubuntu 22.04 LTS
   - Region: us-east (configurable)
   - Storage: 25GB SSD

2. **Docker Containers**
   - OpenVPN Server Container
   - Pi-hole Ad-Blocker Container

3. **Network Configuration**
   - Public IPv4 address
   - UFW firewall with selective port access
   - Docker bridge network for inter-container communication
   - OpenVPN tunnel interface (tun0)

4. **Security Features**
   - SSH key-based authentication
   - Firewall rules restricting access to essential ports only
   - OpenVPN's robust encryption protocols
   - DNS-based ad and malware blocking via Pi-hole

## OpenVPN Technology

### Why OpenVPN?

OpenVPN is a mature, widely-adopted VPN protocol that offers several advantages:

1. **Proven Security**: Battle-tested over 20+ years in production
2. **Cross-Platform**: Excellent support across all major platforms
3. **Flexibility**: Highly configurable with extensive options
4. **Reliability**: Stable and robust connection handling
5. **Community Support**: Large community and extensive documentation
6. **Firewall Traversal**: Works through most firewalls and NAT

### How VPN Tunneling Works

1. **Encryption**: All traffic between client and server is encrypted using AES-256-CBC
2. **Authentication**: X.509 certificates and optional TLS-auth for enhanced security
3. **Integrity**: HMAC SHA-256 ensures data hasn't been tampered with
4. **NAT Traversal**: UDP-based protocol that works behind NAT/firewalls
5. **IP Masquerading**: Server acts as a router, forwarding client traffic to internet

## Pi-hole Ad-Blocking

### What is Pi-hole?

Pi-hole is a DNS sinkhole that acts as a DNS server for the VPN network:

1. **DNS Filtering**: Intercepts DNS queries and blocks requests to ad/tracking domains
2. **Upstream DNS**: Forwards legitimate queries to Cloudflare DNS (1.1.1.1)
3. **Web Interface**: Provides statistics, configuration, and monitoring
4. **Blocklists**: Maintains and updates lists of domains to block
5. **Privacy**: No data sent to third parties, all filtering done locally

### How DNS-Based Ad-Blocking Works

1. **Client Request**: Device tries to access website (e.g., example.com)
2. **DNS Query**: VPN client sends DNS query through tunnel to Pi-hole
3. **Domain Check**: Pi-hole checks if domain is on blocklist
4. **Action**:
   - If blocked: Returns null response (ad not loaded)
   - If allowed: Forwards query to upstream DNS, returns result
5. **Result**: Client receives response and loads content (minus blocked ads)

### Benefits of DNS-Level Blocking

1. **Universal**: Works on all apps and websites without client software
2. **Performance**: Ads never downloaded, saving bandwidth and load time
3. **Privacy**: Blocks tracking domains before they can track you
4. **Malware Protection**: Blocks known malicious domains
5. **Customizable**: Add/remove domains as needed

## Package Dependencies

### Server-Side Packages

1. **Docker & Docker Compose**
   - Purpose: Container orchestration
   - Components: OpenVPN and Pi-hole containers

2. **openvpn** (in container)
   - Purpose: VPN server software
   - Functions: Tunnel creation, encryption, authentication

3. **easy-rsa** (in container)
   - Purpose: Certificate Authority management
   - Functions: Generate and manage SSL certificates

4. **pihole/pihole** (Docker image)
   - Purpose: DNS-based ad-blocker
   - Functions: DNS filtering, web interface, statistics

5. **iptables**
   - Purpose: NAT and packet forwarding rules
   - Function: Enables internet access for VPN clients

6. **ufw (Uncomplicated Firewall)**
   - Purpose: Simplified iptables management
   - Configuration: Allows SSH (22/tcp), OpenVPN (1194/udp), Pi-hole web (80/tcp)

### System Requirements

- **Kernel Support**: Linux kernel with TUN/TAP support
- **IP Forwarding**: Enabled via `net.ipv4.ip_forward = 1`
- **Network Interface**: Public internet connection with static IP
- **Docker**: Version 20.10 or later
- **Docker Compose**: Version 1.29 or later

## Installation Process

### 1. Terraform Infrastructure Deployment

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Deploy infrastructure
terraform apply
```

### 2. Automated Server Configuration

The Terraform provisioners execute the following steps:

1. **System Updates**
   ```bash
   apt-get update
   ```

2. **Docker Installation**
   ```bash
   apt-get install -y docker.io docker-compose
   systemctl start docker
   systemctl enable docker
   ```

3. **IP Forwarding Configuration**
   ```bash
   echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
   sysctl -p
   ```

4. **Docker Compose Deployment**
   - Copy docker-compose.yml and configuration files to server
   - Execute deployment script
   - Start OpenVPN and Pi-hole containers
   - Generate server certificates and client keys

5. **Firewall Configuration**
   ```bash
   ufw allow 22/tcp      # SSH access
   ufw allow 1194/udp    # OpenVPN VPN
   ufw allow 80/tcp      # Pi-hole web interface
   ufw --force enable
   ```

### 3. OpenVPN Configuration Details

#### Server Configuration (`/etc/openvpn/server.conf`)

```ini
port 1194
proto udp
dev tun

# SSL/TLS certificates
ca /etc/openvpn/keys/ca.crt
cert /etc/openvpn/keys/server.crt
key /etc/openvpn/keys/server.key
dh /etc/openvpn/keys/dh.pem

# Network configuration
topology subnet
server 10.8.0.0 255.255.255.0

# Push DNS to clients (Pi-hole for ad-blocking)
push "dhcp-option DNS 10.8.1.2"
push "dhcp-option DNS 1.1.1.1"

# Security settings
tls-auth /etc/openvpn/keys/ta.key 0
cipher AES-256-CBC

# Connection persistence
keepalive 10 120
persist-key
persist-tun

# Logging
status /var/log/openvpn/openvpn-status.log
log /var/log/openvpn/openvpn.log
```

#### Client Configuration (`.ovpn` file)

```ini
client
dev tun
proto udp
remote YOUR_SERVER_IP 1194

# Certificate and keys embedded in file
<ca>
[CA Certificate]
</ca>
<cert>
[Client Certificate]
</cert>
<key>
[Client Private Key]
</key>
<tls-auth>
[TLS Auth Key]
</tls-auth>

# Security settings
cipher AES-256-CBC
auth SHA256

# Connection settings
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server

# Verbosity
verb 3
```

### 4. Pi-hole Configuration

#### Docker Compose Configuration

```yaml
services:
  pihole:
    image: pihole/pihole:latest
    container_name: pihole
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "80:80/tcp"
    environment:
      - TZ=America/New_York
      - WEBPASSWORD=<auto-generated>
      - DNS1=1.1.1.1  # Cloudflare DNS
      - DNS2=1.0.0.1  # Cloudflare DNS
    volumes:
      - pihole-data:/etc/pihole
      - pihole-dnsmasq:/etc/dnsmasq.d
    networks:
      openvpn-network:
        ipv4_address: 10.8.1.2
```

#### Pi-hole Features

1. **Blocklists**: Pre-configured with popular ad/tracking domain lists
2. **Web Interface**: Accessible at http://SERVER_IP/admin
3. **Statistics**: Real-time query logging and statistics
4. **Custom Rules**: Add/remove domains via web interface
5. **DHCP**: Disabled (not needed for VPN use case)

## Network Configuration

### IP Address Allocation

- **Docker Bridge Network**: 10.8.1.0/24
  - Pi-hole: 10.8.1.2
  - OpenVPN Container: Dynamic
- **VPN Tunnel Network**: 10.8.0.0/24
  - Server VPN IP: 10.8.0.1
  - Client VPN IPs: 10.8.0.2 - 10.8.0.254

### Traffic Flow

1. **Client → VPN Server**: Encrypted tunnel via UDP port 1194
2. **VPN → Pi-hole**: DNS queries sent to 10.8.1.2 for filtering
3. **Pi-hole → Upstream DNS**: Allowed queries forwarded to Cloudflare (1.1.1.1)
4. **VPN → Internet**: NAT masquerading through server's public interface
5. **Internet → Server**: Response traffic routed back through tunnel
6. **Server → Client**: Encrypted response via established tunnel

### DNS Configuration

- **Primary DNS**: Pi-hole (10.8.1.2) - Blocks ads and trackers
- **Fallback DNS**: Cloudflare (1.1.1.1) - Used if Pi-hole unavailable
- **Upstream DNS**: Cloudflare (1.1.1.1, 1.0.0.1) - Pi-hole forwards queries here
- **Purpose**: Multi-layer DNS filtering prevents DNS leaks and ensures privacy

## Security Mechanisms

### Cryptographic Protocols

1. **Key Exchange**: RSA 2048-bit for initial handshake
2. **Encryption**: AES-256-CBC symmetric encryption for data
3. **Authentication**: HMAC SHA-256 message authentication
4. **TLS Auth**: Additional HMAC layer for DDoS protection
5. **Certificates**: X.509 certificates with 10-year validity

### Network Security

1. **Firewall Rules**:
   - Default: Deny all incoming connections
   - Allow: SSH (22/tcp) for management
   - Allow: OpenVPN (1194/udp) for VPN
   - Allow: HTTP (80/tcp) for Pi-hole web interface

2. **Authentication**:
   - SSH: Public key authentication only
   - VPN: Certificate-based authentication (no passwords)
   - Pi-hole: Password-protected web interface

3. **Traffic Isolation**:
   - VPN traffic isolated in TUN interface
   - Docker containers on separate bridge network
   - No direct client-to-client communication (default)

4. **DNS Security**:
   - Pi-hole blocks malicious domains
   - Prevents DNS hijacking and spoofing
   - No DNS leaks (all queries through VPN)

## VPN Functionality

### How It Acts as a VPN

1. **Traffic Encryption**:
   - All data between client and server is encrypted
   - Protection against eavesdropping on public networks

2. **IP Address Masking**:
   - Client's real IP address is hidden
   - Internet sees traffic coming from VPN server's IP

3. **Geographic Location Spoofing**:
   - Appears to browse from server's location
   - Bypass geo-restrictions and censorship

4. **Secure Tunneling**:
   - Creates encrypted tunnel through untrusted networks
   - Protects against man-in-the-middle attacks

5. **Ad and Tracker Blocking**:
   - Pi-hole blocks ads before they reach your device
   - Prevents tracking across websites
   - Blocks malware and phishing domains
   - Faster browsing with reduced bandwidth usage

### Use Cases

1. **Privacy Protection**: Hide browsing activity from ISPs
2. **Public WiFi Security**: Secure connections on untrusted networks
3. **Remote Access**: Secure access to home/office networks
4. **Geo-unblocking**: Access region-restricted content
5. **Censorship Circumvention**: Bypass internet restrictions
6. **Ad-Free Browsing**: Block ads on all devices through VPN
7. **Malware Protection**: Block malicious domains at DNS level

## Performance Characteristics

### Expected Performance

- **Bandwidth**: Up to 1 Gbps (limited by Linode instance)
- **Latency**: +10-50ms additional latency
- **Concurrent Connections**: 50-100 clients (with current resources)
- **CPU Usage**: Moderate overhead for OpenVPN, minimal for Pi-hole

### Optimization Features

1. **UDP Protocol**: Lower overhead than TCP-based connections
2. **Persistent Connections**: Maintains connection state efficiently
3. **DNS Caching**: Pi-hole caches DNS queries for faster responses
4. **Ad Blocking**: Reduces bandwidth by not downloading ads
4. **Connection Persistence**: Maintains connections through network changes

## Monitoring and Maintenance

### Health Checks

```bash
# Check OpenVPN status
docker-compose ps
docker-compose logs openvpn

# Check Pi-hole status
docker-compose exec pihole pihole status

# Check connected clients
docker-compose exec openvpn cat /var/log/openvpn/openvpn-status.log

# View Pi-hole statistics
# Access web interface at http://SERVER_IP/admin
```

### Log Locations

- **OpenVPN Logs**: `docker-compose logs openvpn`
- **Pi-hole Logs**: `docker-compose logs pihole`
- **Pi-hole Query Logs**: Via web interface at http://SERVER_IP/admin
- **System Logs**: `/var/log/syslog` on host

### Maintenance Tasks

1. **Regular Updates**: Keep system and Docker images updated
2. **Certificate Management**: Monitor certificate expiration (10-year validity)
3. **Monitoring**: Track bandwidth usage and connection patterns
4. **Backup**: Backup configuration files, certificates, and Pi-hole settings
5. **Pi-hole Updates**: Keep Pi-hole blocklists updated (auto-updates weekly)
6. **Log Rotation**: Monitor and rotate logs to prevent disk space issues

## Troubleshooting

### Common Issues

1. **Connection Failures**:
   - Check firewall rules on server
   - Verify certificates are valid
   - Confirm server IP is correct in client config
   - Check if OpenVPN container is running

2. **Performance Issues**:
   - Monitor server resources with `docker stats`
   - Check network connectivity
   - Verify MTU settings if needed

3. **DNS Problems**:
   - Verify Pi-hole is running: `docker-compose ps`
   - Check Pi-hole logs: `docker-compose logs pihole`
   - Test DNS resolution from VPN client
   - Verify no DNS leaks at https://dnsleaktest.com

4. **Ads Still Showing**:
   - Clear browser cache and cookies
   - Check Pi-hole blocklists are updated
   - Some ads may use same domain as content
   - Verify client is using Pi-hole DNS (check Pi-hole query log)

### Diagnostic Commands

```bash
# Test VPN connectivity
ping 10.8.0.1

# Test Pi-hole DNS
nslookup google.com 10.8.1.2

# Check Docker containers
docker-compose ps

# View OpenVPN logs
docker-compose logs --tail=100 openvpn

# View Pi-hole logs
docker-compose logs --tail=100 pihole

# Check OpenVPN connected clients
docker-compose exec openvpn cat /var/log/openvpn/openvpn-status.log
```

## Cost Considerations

### Linode Pricing (as of 2025)

- **g6-nanode-1**: ~$5/month
- **Network Transfer**: 1TB included, $0.01/GB overage
- **Total Monthly Cost**: ~$5-10 depending on usage

### Cost Optimization

1. **Right-sizing**: Start with smallest instance, scale if needed
2. **Traffic Monitoring**: Monitor bandwidth to avoid overage charges
3. **Regional Selection**: Choose closest region to minimize latency

## Security Best Practices

1. **Key Management**:
   - Store private keys securely
   - Use different keys for each client
   - Rotate keys periodically

2. **Access Control**:
   - Limit SSH access to trusted IPs
   - Use strong passwords for system accounts
   - Implement fail2ban for brute-force protection

3. **Monitoring**:
   - Log all VPN connections
   - Monitor for unusual traffic patterns
   - Set up alerting for security events

4. **Updates**:
   - Keep system packages updated
   - Monitor security advisories
   - Have rollback plan for updates

## Conclusion

This Linode OpenVPN + Pi-hole solution provides a robust, secure, and ad-free personal VPN service. The combination of OpenVPN's proven security, Pi-hole's effective ad-blocking, and cloud infrastructure ensures reliable privacy protection with enhanced browsing experience and minimal maintenance overhead.

The OpenVPN protocol's maturity and cross-platform support combined with Pi-hole's DNS-based filtering make it an excellent choice for a complete privacy and ad-blocking solution, while Terraform's infrastructure automation ensures reproducible and manageable deployments.
