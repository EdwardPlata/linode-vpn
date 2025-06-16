# Linode WireGuard VPN Technical Documentation

## Overview

This project deploys a secure WireGuard VPN server on Linode infrastructure using Terraform for Infrastructure as Code (IaC). The solution provides a personal VPN service that encrypts internet traffic, protects privacy, and allows secure access to remote networks.

## Architecture

### Infrastructure Components

1. **Linode Compute Instance**
   - Type: g6-nanode-1 (1GB RAM, 1 CPU core)
   - Operating System: Ubuntu 22.04 LTS
   - Region: us-east (configurable)
   - Storage: 25GB SSD

2. **Network Configuration**
   - Public IPv4 address
   - UFW firewall with selective port access
   - WireGuard VPN tunnel interface (wg0)

3. **Security Features**
   - SSH key-based authentication
   - Firewall rules restricting access to essential ports only
   - WireGuard's modern cryptographic protocols

## WireGuard VPN Technology

### Why WireGuard?

WireGuard is a modern VPN protocol that offers several advantages over traditional solutions:

1. **Performance**: Faster than OpenVPN and IPSec due to optimized code
2. **Security**: Uses state-of-the-art cryptography (ChaCha20, Poly1305, BLAKE2s, X25519)
3. **Simplicity**: Minimal codebase (~4,000 lines vs 600,000+ for OpenVPN)
4. **Battery Efficiency**: Lower power consumption on mobile devices
5. **Ease of Configuration**: Simple configuration files

### How VPN Tunneling Works

1. **Encryption**: All traffic between client and server is encrypted using ChaCha20
2. **Authentication**: Curve25519 elliptic curve cryptography for key exchange
3. **Integrity**: Poly1305 authenticator ensures data hasn't been tampered with
4. **NAT Traversal**: UDP-based protocol that works behind NAT/firewalls
5. **IP Masquerading**: Server acts as a router, forwarding client traffic to internet

## Package Dependencies

### Server-Side Packages

1. **wireguard** (Meta-package)
   - Purpose: Installs complete WireGuard suite
   - Dependencies: wireguard-tools, wireguard-dkms (if needed)

2. **wireguard-tools** 
   - Purpose: Provides `wg` and `wg-quick` utilities
   - Functions: Key generation, interface management, configuration

3. **ufw (Uncomplicated Firewall)**
   - Purpose: Simplified iptables management
   - Configuration: Allows SSH (22/tcp) and WireGuard (51820/udp)

4. **iptables** (Pre-installed)
   - Purpose: NAT and packet forwarding rules
   - Function: Enables internet access for VPN clients

### System Requirements

- **Kernel Support**: Linux kernel 5.6+ (native) or DKMS module for older kernels
- **IP Forwarding**: Enabled via `net.ipv4.ip_forward = 1`
- **Network Interface**: Public internet connection with static IP

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

2. **WireGuard Installation**
   ```bash
   apt-get install -y wireguard wireguard-tools
   ```

3. **IP Forwarding Configuration**
   ```bash
   echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
   sysctl -p
   ```

4. **WireGuard Setup Script Execution**
   - Copy setup script to server
   - Execute configuration script
   - Generate server and client keys
   - Create configuration files

5. **Firewall Configuration**
   ```bash
   ufw allow 22/tcp      # SSH access
   ufw allow 51820/udp   # WireGuard VPN
   ufw --force enable
   ```

### 3. WireGuard Configuration Details

#### Server Configuration (`/etc/wireguard/wg0.conf`)

```ini
[Interface]
Address = 10.8.0.1/24          # Server VPN IP address
ListenPort = 51820              # WireGuard listening port
PrivateKey = <SERVER_PRIVATE_KEY>
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = <CLIENT_PUBLIC_KEY>
AllowedIPs = 10.8.0.2/32       # Client VPN IP address
```

#### Client Configuration (`/root/wireguard-clients/client.conf`)

```ini
[Interface]
PrivateKey = <CLIENT_PRIVATE_KEY>
Address = 10.8.0.2/24          # Client VPN IP address
DNS = 1.1.1.1, 8.8.8.8         # DNS servers

[Peer]
PublicKey = <SERVER_PUBLIC_KEY>
Endpoint = <SERVER_PUBLIC_IP>:51820
AllowedIPs = 0.0.0.0/0, ::/0   # Route all traffic through VPN
PersistentKeepalive = 25        # Keep connection alive through NAT
```

## Network Configuration

### IP Address Allocation

- **VPN Network**: 10.8.0.0/24
- **Server VPN IP**: 10.8.0.1
- **Client VPN IP**: 10.8.0.2
- **Available Client IPs**: 10.8.0.3 - 10.8.0.254

### Traffic Flow

1. **Client → Server**: Encrypted tunnel via UDP port 51820
2. **Server → Internet**: NAT masquerading through public interface
3. **Internet → Server**: Response traffic routed back through tunnel
4. **Server → Client**: Encrypted response via established tunnel

### DNS Configuration

- **Primary DNS**: 1.1.1.1 (Cloudflare)
- **Secondary DNS**: 8.8.8.8 (Google)
- **Purpose**: Prevents DNS leaks and ensures privacy

## Security Mechanisms

### Cryptographic Protocols

1. **Key Exchange**: Curve25519 elliptic curve Diffie-Hellman
2. **Encryption**: ChaCha20 stream cipher
3. **Authentication**: Poly1305 message authentication code
4. **Hashing**: BLAKE2s cryptographic hash function

### Network Security

1. **Firewall Rules**:
   - Default: Deny all incoming connections
   - Allow: SSH (22/tcp) for management
   - Allow: WireGuard (51820/udp) for VPN

2. **Authentication**:
   - SSH: Public key authentication only
   - VPN: Cryptographic key pairs (no passwords)

3. **Traffic Isolation**:
   - VPN traffic isolated in separate network namespace
   - No direct access between VPN clients (default)

## VPN Functionality

### How It Acts as a VPN

1. **Traffic Encryption**:
   - All data between client and server is encrypted
   - Protection against eavesdropping on public networks

2. **IP Address Masking**:
   - Client's real IP address is hidden
   - Internet sees traffic coming from VPN server's IP

3. **Geographic Location Spoofing**:
   - Appears to browse from server's location (us-east)
   - Bypass geo-restrictions and censorship

4. **Secure Tunneling**:
   - Creates encrypted tunnel through untrusted networks
   - Protects against man-in-the-middle attacks

### Use Cases

1. **Privacy Protection**: Hide browsing activity from ISPs
2. **Public WiFi Security**: Secure connections on untrusted networks
3. **Remote Access**: Secure access to home/office networks
4. **Geo-unblocking**: Access region-restricted content
5. **Censorship Circumvention**: Bypass internet restrictions

## Performance Characteristics

### Expected Performance

- **Bandwidth**: Up to 1 Gbps (limited by Linode instance)
- **Latency**: +10-50ms additional latency
- **Concurrent Connections**: 50-100 clients (with current resources)
- **CPU Usage**: Minimal overhead due to WireGuard efficiency

### Optimization Features

1. **UDP Protocol**: Lower overhead than TCP-based VPNs
2. **Kernel Integration**: Native kernel module for best performance
3. **Efficient Cryptography**: Modern ciphers optimized for speed
4. **Connection Persistence**: Maintains connections through network changes

## Monitoring and Maintenance

### Health Checks

```bash
# Check WireGuard status
wg show

# Check service status
systemctl status wg-quick@wg0

# Monitor connections
journalctl -u wg-quick@wg0 -f
```

### Log Locations

- **WireGuard Logs**: `journalctl -u wg-quick@wg0`
- **System Logs**: `/var/log/syslog`
- **Firewall Logs**: `/var/log/ufw.log`

### Maintenance Tasks

1. **Regular Updates**: Keep system and packages updated
2. **Key Rotation**: Periodically regenerate WireGuard keys
3. **Monitoring**: Track bandwidth usage and connection patterns
4. **Backup**: Backup configuration files and keys

## Troubleshooting

### Common Issues

1. **Connection Failures**:
   - Check firewall rules
   - Verify key configurations
   - Confirm endpoint accessibility

2. **Performance Issues**:
   - Monitor server resources
   - Check network connectivity
   - Verify MTU settings

3. **DNS Problems**:
   - Test DNS resolution
   - Check DNS server configuration
   - Verify no DNS leaks

### Diagnostic Commands

```bash
# Test connectivity
ping 10.8.0.1

# Check interface status
ip addr show wg0

# Monitor traffic
tcpdump -i wg0

# Check routing
ip route show table all
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

This Linode WireGuard VPN solution provides a robust, secure, and cost-effective personal VPN service. The combination of modern cryptography, automated deployment, and cloud infrastructure ensures reliable privacy protection with minimal maintenance overhead.

The WireGuard protocol's efficiency and security make it an excellent choice for personal VPN needs, while Terraform's infrastructure automation ensures reproducible and manageable deployments.
