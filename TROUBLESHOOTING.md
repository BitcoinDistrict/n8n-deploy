# n8n Automation Stack - Troubleshooting Guide

This guide provides comprehensive troubleshooting commands and procedures for diagnosing and resolving issues with your n8n automation stack running on Ubuntu with Docker Compose.

## Table of Contents

- [Stack Overview](#stack-overview)
- [Quick Diagnostics](#quick-diagnostics)
- [System Resource Monitoring](#system-resource-monitoring)
- [Docker Container Management](#docker-container-management)
- [Log Inspection](#log-inspection)
- [Network Troubleshooting](#network-troubleshooting)
- [Performance Optimization Diagnostics](#performance-optimization-diagnostics)
- [Common Issues & Solutions](#common-issues--solutions)
- [Emergency Procedures](#emergency-procedures)

## Stack Overview

Your n8n automation stack consists of:
- **n8n**: Workflow automation tool (docker.n8n.io/n8nio/n8n:latest)
- **Caddy**: Reverse proxy with automatic HTTPS (caddy:2)
- **Watchtower**: Automatic container updates (containrrr/watchtower)
- **System Optimizations**: ZRAM/swap, kernel tuning, systemd optimization

**Deployment Location**: `/opt/n8n/`
**Configuration Files**: `docker-compose.yml`, `Caddyfile`, `.env`

## Quick Diagnostics

### Overall Stack Status
```bash
# Check all containers status
cd /opt/n8n && docker compose ps

# Quick health check
cd /opt/n8n && docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

# Check if all services are running
systemctl is-active docker
cd /opt/n8n && docker compose top
```

### Container Resource Usage
```bash
# Real-time resource usage for all containers
docker stats

# Resource usage for specific containers
docker stats n8n-n8n-1 n8n-caddy-1 n8n-watchtower-1

# Container resource limits and usage
docker inspect n8n-n8n-1 | jq '.[0].HostConfig.Memory'
```

## System Resource Monitoring

### Memory Usage
```bash
# Overall memory usage
free -h

# Detailed memory breakdown
cat /proc/meminfo | head -20

# Memory usage by process
ps aux --sort=-%mem | head -10

# Check for memory pressure
dmesg | grep -i "killed process\|out of memory\|oom"

# ZRAM status (if enabled)
cat /proc/swaps
zramctl
```

### CPU Usage
```bash
# Current CPU usage
top -bn1 | grep "Cpu(s)"

# CPU usage by process
ps aux --sort=-%cpu | head -10

# System load averages
uptime

# CPU information
lscpu

# Check for high CPU processes
htop  # Interactive view
```

### Swap Usage
```bash
# Swap usage overview
swapon --show

# Swap usage details
cat /proc/swaps

# Memory and swap usage
free -h

# Check swap activity
vmstat 1 5

# ZRAM compression ratio (if using ZRAM)
cat /sys/block/zram*/mm_stat 2>/dev/null
```

### Disk Usage
```bash
# Disk space usage
df -h

# Docker space usage
docker system df

# Docker volumes usage
docker volume ls
docker system df -v

# Check for large files
du -h /opt/n8n/ | sort -hr | head -10

# Inode usage
df -i
```

## Docker Container Management

### Container Status and Health
```bash
# Detailed container status
cd /opt/n8n && docker compose ps -a

# Container health checks
docker inspect n8n-n8n-1 | jq '.[0].State.Health'

# Container uptime and restart count
docker inspect n8n-n8n-1 | jq '.[0].State | {Status, StartedAt, RestartCount}'

# Process list inside containers
docker compose top
```

### Restarting Containers

#### Restart Individual Services
```bash
cd /opt/n8n

# Restart n8n only
docker compose restart n8n

# Restart Caddy only
docker compose restart caddy

# Restart Watchtower only
docker compose restart watchtower
```

#### Restart Entire Stack
```bash
cd /opt/n8n

# Graceful restart (recommended)
docker compose restart

# Force restart (if containers are unresponsive)
docker compose down && docker compose up -d

# Complete rebuild (if containers are corrupted)
docker compose down
docker compose pull
docker compose up -d
```

### Container Diagnostics
```bash
# Enter container shell for debugging
docker compose exec n8n sh
docker compose exec caddy sh

# Run commands inside containers
docker compose exec n8n node --version
docker compose exec caddy caddy version

# Check container environment variables
docker compose exec n8n env

# Container resource usage
docker compose exec n8n cat /proc/meminfo
docker compose exec n8n ps aux
```

### Container Network Diagnostics
```bash
# Check container networking
docker network ls
docker network inspect n8n_default

# Test connectivity between containers
docker compose exec caddy ping n8n
docker compose exec n8n ping caddy

# Check port bindings
docker compose port caddy 80
docker compose port caddy 443
```

## Log Inspection

### Docker Compose Logs
```bash
cd /opt/n8n

# All container logs (recent)
docker compose logs

# Follow logs in real-time
docker compose logs -f

# Logs for specific service
docker compose logs n8n
docker compose logs caddy
docker compose logs watchtower

# Logs with timestamps
docker compose logs -t

# Last 100 lines of logs
docker compose logs --tail=100

# Logs from specific time
docker compose logs --since="2024-01-01T10:00:00"
```

### Individual Container Logs
```bash
# n8n application logs
docker logs n8n-n8n-1 -f

# Caddy proxy logs
docker logs n8n-caddy-1 -f

# Watchtower update logs
docker logs n8n-watchtower-1 -f

# Container logs with timestamps and details
docker logs n8n-n8n-1 --timestamps --details

# Export logs to file
docker logs n8n-n8n-1 > n8n-logs.txt 2>&1
```

### System Logs
```bash
# Docker daemon logs
journalctl -u docker.service -f

# System logs related to containers
journalctl -f | grep -i docker

# System resource logs
journalctl -f | grep -i "memory\|swap\|oom"

# Boot logs
dmesg | grep -i error

# Check systemd service status
systemctl status docker
```

### Application-Specific Logs
```bash
# n8n workflow execution logs (inside container)
docker compose exec n8n ls -la /home/node/.n8n/logs/

# Caddy access logs (if enabled)
docker compose exec caddy ls -la /data/caddy/logs/

# Check for application errors
docker compose logs n8n | grep -i error
docker compose logs caddy | grep -i error
```

## Network Troubleshooting

### Port and Service Accessibility
```bash
# Check if ports are listening
netstat -tlnp | grep -E "(80|443|5678)"
ss -tlnp | grep -E "(80|443|5678)"

# Test local connectivity
curl -I http://localhost:80
curl -I https://localhost:443

# Test n8n service directly
curl -I http://localhost:5678  # This should fail from outside (internal only)

# Check UFW firewall status
ufw status verbose

# Test external connectivity (replace with your domain)
curl -I https://your-domain.com
```

### DNS and SSL Troubleshooting
```bash
# Check DNS resolution
nslookup your-domain.com
dig your-domain.com

# Test SSL certificate
openssl s_client -connect your-domain.com:443 -servername your-domain.com

# Caddy certificate status
docker compose exec caddy caddy list-certificates

# Check Caddy configuration
docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile
```

## Performance Optimization Diagnostics

### ZRAM Status
```bash
# Check if ZRAM is active
lsblk | grep zram
zramctl

# ZRAM statistics
cat /sys/block/zram*/stat
cat /sys/block/zram*/mm_stat

# ZRAM compression ratio
for i in /sys/block/zram*; do
    echo "=== $(basename $i) ==="
    echo "Size: $(cat $i/disksize)"
    echo "Used: $(cat $i/mm_stat | awk '{print $1}')"
    echo "Compressed: $(cat $i/mm_stat | awk '{print $2}')"
done
```

### Swap Configuration
```bash
# Current swap settings
sysctl vm.swappiness
sysctl vm.vfs_cache_pressure
cat /proc/sys/vm/swappiness

# Swap usage by process
for file in /proc/*/status; do
    awk '/VmSwap|Name/{printf $2 " " $3}END{ print ""}' $file 2>/dev/null
done | sort -k2 -n | tail -10
```

### Systemd Performance Settings
```bash
# Check systemd limits
systemctl show --property=DefaultLimitNOFILE
systemctl show --property=DefaultLimitNPROC

# Check current limits
ulimit -a

# Check systemd-oomd status
systemctl status systemd-oomd
```

### Network Optimization Status
```bash
# Check TCP congestion control
sysctl net.ipv4.tcp_congestion_control
sysctl net.core.default_qdisc

# Check network buffer sizes
sysctl net.core.rmem_max
sysctl net.core.wmem_max
sysctl net.ipv4.tcp_rmem
sysctl net.ipv4.tcp_wmem

# Network connection statistics
ss -s
netstat -i
```

## Common Issues & Solutions

### Container Seizing/Hanging Issues

#### Symptoms
- Container appears running but doesn't respond
- High CPU usage with no activity
- Memory usage continuously climbing
- Web interface becomes unresponsive

#### Diagnostic Commands
```bash
# Check container process status
docker compose exec n8n ps aux

# Check container resource limits
docker stats --no-stream n8n-n8n-1

# Check for deadlocks or blocked processes
docker compose exec n8n cat /proc/loadavg
docker compose exec n8n top -bn1

# Check container logs for errors
docker compose logs n8n --tail=50 | grep -i "error\|exception\|timeout"

# Check system memory pressure
dmesg | tail -20 | grep -i "memory\|oom"
```

#### Solutions
```bash
# Gentle restart (try first)
cd /opt/n8n && docker compose restart n8n

# Force restart if unresponsive
docker kill n8n-n8n-1
cd /opt/n8n && docker compose up -d n8n

# Complete restart with cleanup
cd /opt/n8n
docker compose down
docker system prune -f
docker compose up -d
```

### High Memory Usage
```bash
# Identify memory-hungry processes
docker compose exec n8n ps aux --sort=-%mem

# Check for memory leaks in n8n
docker stats n8n-n8n-1 --no-stream

# Clear system caches (if safe to do)
sync && echo 3 > /proc/sys/vm/drop_caches

# Restart containers to free memory
cd /opt/n8n && docker compose restart
```

### SSL/Certificate Issues
```bash
# Check Caddy certificate status
docker compose logs caddy | grep -i certificate

# Manually trigger certificate renewal
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile

# Check certificate files
docker compose exec caddy ls -la /data/caddy/certificates/
```

### Disk Space Issues
```bash
# Clean Docker system
docker system prune -af --volumes

# Clean old logs
journalctl --vacuum-time=7d

# Check large files in n8n data
docker compose exec n8n du -h /home/node/.n8n | sort -hr | head -10
```

## Emergency Procedures

### Complete Stack Recovery
```bash
# Stop all containers
cd /opt/n8n && docker compose down

# Backup current configuration
cp -r /opt/n8n /opt/n8n-backup-$(date +%Y%m%d-%H%M%S)

# Clean Docker system
docker system prune -af
docker volume prune -f

# Restart Docker daemon
systemctl restart docker

# Rebuild and start stack
cd /opt/n8n
docker compose pull
docker compose up -d

# Monitor startup
docker compose logs -f
```

### System Recovery
```bash
# Free up memory immediately
sync && echo 3 > /proc/sys/vm/drop_caches

# Kill resource-heavy processes (be careful!)
pkill -f n8n  # Only if container restart doesn't work

# Restart Docker service
systemctl restart docker

# Check system health
systemctl status
free -h
df -h
```

### Log Collection for Support
```bash
# Create comprehensive log bundle
mkdir -p /tmp/n8n-diagnostics
cd /tmp/n8n-diagnostics

# System information
uname -a > system-info.txt
free -h > memory-info.txt
df -h > disk-info.txt
docker version > docker-info.txt
docker compose version >> docker-info.txt

# Container logs
cd /opt/n8n
docker compose logs > /tmp/n8n-diagnostics/container-logs.txt

# System logs
journalctl -u docker.service --since="1 hour ago" > /tmp/n8n-diagnostics/docker-service.log

# Configuration files (without secrets)
cp docker-compose.yml /tmp/n8n-diagnostics/
cp Caddyfile /tmp/n8n-diagnostics/

# Create archive
cd /tmp
tar -czf n8n-diagnostics-$(date +%Y%m%d-%H%M%S).tar.gz n8n-diagnostics/
echo "Diagnostic bundle created: /tmp/n8n-diagnostics-$(date +%Y%m%d-%H%M%S).tar.gz"
```

## Monitoring Scripts

### Quick Health Check Script
```bash
#!/bin/bash
# Save as: /usr/local/bin/n8n-health-check

echo "=== n8n Stack Health Check ==="
echo "Date: $(date)"
echo

echo "=== Container Status ==="
cd /opt/n8n && docker compose ps
echo

echo "=== Resource Usage ==="
free -h
echo
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
echo

echo "=== Disk Usage ==="
df -h /opt/n8n
echo

echo "=== Recent Errors ==="
cd /opt/n8n && docker compose logs --since="10m" | grep -i error | tail -5
```

### Continuous Monitoring
```bash
# Monitor container stats in real-time
watch -n 5 'cd /opt/n8n && docker compose ps && echo && docker stats --no-stream'

# Monitor logs in real-time
cd /opt/n8n && docker compose logs -f | grep -E "(error|warning|exception)" --color=always

# Monitor system resources
watch -n 2 'free -h && echo && df -h && echo && uptime'
```

---

## Quick Reference Commands

```bash
# Essential Commands Cheat Sheet

# Check stack status
cd /opt/n8n && docker compose ps

# Restart n8n container (most common fix)
cd /opt/n8n && docker compose restart n8n

# View recent logs
cd /opt/n8n && docker compose logs --tail=50

# Check resource usage
docker stats --no-stream

# System resource check
free -h && df -h && uptime

# Emergency restart
cd /opt/n8n && docker compose down && docker compose up -d

# Full cleanup and restart
cd /opt/n8n && docker compose down && docker system prune -f && docker compose up -d
```

Remember to replace `your-domain.com` with your actual domain name in the network troubleshooting commands.
