#!/system/bin/sh
# Network restriction script for GrapheneOS
# This script applies iptables rules to restrict outbound network traffic
# to only specific whitelisted servers.
# Used for Tiny Web devices to restrict network access to only Tiny Web nodes.

# ============================================================================
# CONFIGURATION - Modify these values for your allowed servers
# ============================================================================

# Allowed server IPs (space-separated list)
# Example: ALLOWED_IPS="192.0.2.1 198.51.100.1"
ALLOWED_IPS=""

# Allowed server domains (space-separated list)
# Note: Domain-based filtering requires DNS resolution
# Example: ALLOWED_DOMAINS="example.com api.example.com"
ALLOWED_DOMAINS=""

# DNS servers to allow (required for domain resolution)
# Default: Google DNS
DNS_SERVERS="8.8.8.8 8.8.4.4"

# Allowed ports (space-separated list)
# If empty, all ports are allowed for whitelisted IPs
# Example: ALLOWED_PORTS="80 443 53"
ALLOWED_PORTS=""

# ============================================================================
# IMPLEMENTATION - Do not modify below unless you know what you're doing
# ============================================================================

log() {
    echo "[restrict_network] $1" >> /dev/kmsg
}

log "Starting network restriction script"

# Flush existing OUTPUT rules
iptables -F OUTPUT 2>/dev/null
ip6tables -F OUTPUT 2>/dev/null

# Set default policy to DROP for OUTPUT
iptables -P OUTPUT DROP
ip6tables -P OUTPUT DROP 2>/dev/null

# Allow loopback traffic
iptables -A OUTPUT -o lo -j ACCEPT
ip6tables -A OUTPUT -o lo -j ACCEPT 2>/dev/null

# Allow established and related connections (for responses)
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
ip6tables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null

# Allow DNS servers
for dns in $DNS_SERVERS; do
    iptables -A OUTPUT -d $dns -p udp --dport 53 -j ACCEPT
    iptables -A OUTPUT -d $dns -p tcp --dport 53 -j ACCEPT
    ip6tables -A OUTPUT -d $dns -p udp --dport 53 -j ACCEPT 2>/dev/null
    ip6tables -A OUTPUT -d $dns -p tcp --dport 53 -j ACCEPT 2>/dev/null
done

# Allow whitelisted IPs
if [ -n "$ALLOWED_IPS" ]; then
    for ip in $ALLOWED_IPS; do
        if [ -n "$ALLOWED_PORTS" ]; then
            # If ports are specified, only allow those ports
            for port in $ALLOWED_PORTS; do
                iptables -A OUTPUT -d $ip -p tcp --dport $port -j ACCEPT
                iptables -A OUTPUT -d $ip -p udp --dport $port -j ACCEPT
                ip6tables -A OUTPUT -d $ip -p tcp --dport $port -j ACCEPT 2>/dev/null
                ip6tables -A OUTPUT -d $ip -p udp --dport $port -j ACCEPT 2>/dev/null
            done
        else
            # Allow all ports for this IP
            iptables -A OUTPUT -d $ip -j ACCEPT
            ip6tables -A OUTPUT -d $ip -j ACCEPT 2>/dev/null
        fi
        log "Allowed IP: $ip"
    done
fi

# Allow whitelisted domains (requires DNS resolution)
# Note: This is less reliable than IP-based filtering
if [ -n "$ALLOWED_DOMAINS" ]; then
    for domain in $ALLOWED_DOMAINS; do
        # Resolve domain to IP (may fail if DNS not working yet)
        resolved_ip=$(getent hosts $domain | awk '{print $1}' | head -1)
        if [ -n "$resolved_ip" ]; then
            if [ -n "$ALLOWED_PORTS" ]; then
                for port in $ALLOWED_PORTS; do
                    iptables -A OUTPUT -d $resolved_ip -p tcp --dport $port -j ACCEPT
                    iptables -A OUTPUT -d $resolved_ip -p udp --dport $port -j ACCEPT
                done
            else
                iptables -A OUTPUT -d $resolved_ip -j ACCEPT
            fi
            log "Allowed domain: $domain -> $resolved_ip"
        else
            log "Warning: Could not resolve domain: $domain"
        fi
    done
fi

log "Network restriction rules applied"

# Verify rules (for debugging - remove in production)
# iptables -L OUTPUT -n -v >> /dev/kmsg

