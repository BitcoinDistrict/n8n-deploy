# Performance Optimization Role

This Ansible role optimizes performance for tiny Ubuntu VMs by implementing various system-level improvements. It includes proper OS detection to ensure compatibility and safety.

## Features

### 1. Swap Management
- **ZRAM**: Preferred for VMs with < 2GB RAM (fast, compressed, in-memory)
- **Swapfile**: Fallback for larger VMs (persistent, disk-based)
- **Memory tuning**: Conservative vm.swappiness and VFS cache pressure settings

### 2. Kernel/Network Tuning
- **BBR Congestion Control**: Enabled if available, with fq qdisc
- **TCP Optimizations**: Window scaling, SACK, timestamps, fastopen
- **Buffer Sizes**: Mild increases appropriate for tiny VMs
- **Connection Limits**: Conservative settings for small systems

### 3. Systemd/Journald Optimization
- **Journal Size Limits**: Prevents disk space issues (100MB max)
- **Reduced Sync Frequency**: Improves I/O performance
- **systemd-oomd**: Conservative thresholds for memory pressure
- **Service Timeouts**: Faster boot/shutdown times

### 4. Filesystem/I/O Optimization
- **File Descriptor Limits**: Raised to 65536 (common bottleneck)
- **I/O Schedulers**: Automatic optimization based on storage type
- **Inotify Limits**: Increased for applications watching many files
- **Optional noatime**: Opt-in for read-heavy servers

## Usage

### Basic Usage
The role is automatically included in the main playbook when `enable_performance_optimization` is true (default).

### Disable Performance Optimization
```yaml
# In playbook.yml or as extra vars
enable_performance_optimization: false
```

### Run Only Performance Optimization
```bash
ansible-playbook -i inventory.ini playbook.yml --tags "performance"
```

### Run Specific Optimizations
```bash
# Only swap optimization
ansible-playbook -i inventory.ini playbook.yml --tags "swap"

# Only network tuning
ansible-playbook -i inventory.ini playbook.yml --tags "network"

# Only systemd optimization
ansible-playbook -i inventory.ini playbook.yml --tags "systemd"

# Only filesystem optimization  
ansible-playbook -i inventory.ini playbook.yml --tags "filesystem"
```

## Configuration Variables

All variables have sensible defaults but can be overridden:

```yaml
# Swap configuration
performance_optimization_enable_swap: true
performance_optimization_zram_threshold_mb: 2048
performance_optimization_swap_size_ratio: 0.5

# Memory management
performance_optimization_swappiness: 10
performance_optimization_vfs_cache_pressure: 50

# Network optimization
performance_optimization_enable_bbr: true

# Systemd optimization
performance_optimization_journal_max_use: "100M"
performance_optimization_enable_oomd: true

# Filesystem optimization
performance_optimization_max_open_files: 65536
performance_optimization_enable_noatime: false  # Set to true for read-heavy servers
```

## OS Compatibility

This role is designed specifically for **Ubuntu** systems and includes safety checks:

- ✅ Ubuntu 20.04, 22.04, 24.04
- ❌ Other Linux distributions (will fail with clear error message)
- ❌ Windows (will fail with clear error message)

## What Gets Modified

### Files Created/Modified
- `/etc/sysctl.d/60-memory-optimization.conf` - Memory settings
- `/etc/sysctl.d/70-network-optimization.conf` - Network settings  
- `/etc/sysctl.d/80-filesystem-optimization.conf` - Filesystem settings
- `/etc/systemd/journald.conf` - Journal configuration
- `/etc/systemd/system.conf` - Systemd settings
- `/etc/systemd/user.conf` - User service settings
- `/etc/security/limits.conf` - File descriptor limits
- `/etc/default/zramswap` - ZRAM configuration (if used)
- `/etc/fstab` - Swapfile entry (if used)

### Services
- `zramswap.service` - ZRAM swap (if enabled)
- `systemd-oomd.service` - Memory pressure handling (if available)
- `io-scheduler-optimization.service` - I/O scheduler tuning

### Optional Services
- `noatime-optimization.service` - Enable with `systemctl enable noatime-optimization.service`

## Verification

After running the role, you can verify the optimizations:

```bash
# Check swap configuration
swapon --show
cat /proc/swaps

# Check sysctl settings
sysctl vm.swappiness
sysctl net.ipv4.tcp_congestion_control
sysctl fs.file-max

# Check file descriptor limits
ulimit -n

# Check journal size
journalctl --disk-usage

# Check I/O schedulers
cat /sys/block/*/queue/scheduler
```

## Safety Features

- **OS Detection**: Only runs on Ubuntu systems
- **Backup Files**: All configuration files are backed up before modification
- **Conservative Settings**: All tuning values are conservative and tested
- **Opt-in Features**: Potentially disruptive features (like noatime) are opt-in only
- **Idempotent**: Safe to run multiple times

## Performance Impact

Expected improvements on tiny VMs:
- **Memory**: Better handling of memory pressure, reduced swapping
- **Network**: Improved TCP performance, especially for web applications
- **I/O**: Faster file operations, reduced journal overhead
- **Boot Time**: Faster startup and shutdown
- **Responsiveness**: Better handling of low-memory situations
