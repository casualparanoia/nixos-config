# crash-monitor.nix
{ config, lib, pkgs, ... }:

let
  logDir = "/var/log/crash-monitor";

  commonPath = with pkgs; [
    coreutils
    procps
    util-linux
    systemd
    pciutils
    gnugrep
    gnused
    gawk
    findutils
  ];

  # --------------------------------------------------------------------------
  # Periodic state snapshot
  #
  # This is deliberately overwritten rather than accumulated. We care about
  # the state immediately before a crash.
  # --------------------------------------------------------------------------
  snapshotScript = pkgs.writeShellScript "crash-monitor-snapshot" ''
    set -u

    dir="${logDir}"
    tmp="$dir/state-last.tmp"
    out="$dir/state-last.txt"

    {
      echo "============================================================"
      echo "TIMESTAMP"
      echo "============================================================"
      date --iso-8601=ns
      echo

      echo "============================================================"
      echo "UPTIME / LOAD"
      echo "============================================================"
      uptime
      cat /proc/loadavg
      echo

      echo "============================================================"
      echo "KERNEL COMMAND LINE"
      echo "============================================================"
      cat /proc/cmdline
      echo

      echo "============================================================"
      echo "PRESSURE STALL INFORMATION"
      echo "============================================================"
      for f in /proc/pressure/cpu /proc/pressure/io /proc/pressure/memory; do
        echo "--- $f ---"
        cat "$f" 2>/dev/null || true
      done
      echo

      echo "============================================================"
      echo "MEMORY"
      echo "============================================================"
      cat /proc/meminfo
      echo

      echo "============================================================"
      echo "PROCESSES"
      echo "============================================================"
      ps -eo \
        pid,ppid,psr,state,wchan:32,ni,pri,pcpu,pmem,comm,args \
        --sort=-pcpu \
        | head -n 200
      echo

      echo "============================================================"
      echo "UNINTERRUPTIBLE (D-STATE) TASKS"
      echo "============================================================"
      ps -eo pid,ppid,psr,state,wchan:40,comm,args \
        | awk '$4 ~ /D/ { print }'
      echo

      echo "============================================================"
      echo "INTERRUPTS"
      echo "============================================================"
      cat /proc/interrupts
      echo

      echo "============================================================"
      echo "AMDGPU MODULE PARAMETERS"
      echo "============================================================"
      for p in \
        aspm \
        runpm \
        dpm \
        gpu_recovery \
        lockup_timeout \
        debug_mask
      do
        f="/sys/module/amdgpu/parameters/$p"
        if [ -r "$f" ]; then
          printf '%-20s ' "$p:"
          cat "$f"
        fi
      done
      echo

      echo "============================================================"
      echo "AMDGPU SYSFS POWER STATE"
      echo "============================================================"
      for dev in /sys/class/drm/card*/device; do
        [ -e "$dev" ] || continue

        echo "--- $dev ---"

        for f in \
          power/control \
          power/runtime_status \
          power_dpm_state \
          power_dpm_force_performance_level \
          gpu_busy_percent
        do
          if [ -r "$dev/$f" ]; then
            printf '%-40s ' "$f:"
            cat "$dev/$f"
          fi
        done
      done
      echo

      echo "============================================================"
      echo "AMDGPU DEBUGFS PM INFO"
      echo "============================================================"
      for f in /sys/kernel/debug/dri/*/amdgpu_pm_info; do
        [ -r "$f" ] || continue
        echo "--- $f ---"
        cat "$f" || true
      done
      echo

      echo "============================================================"
      echo "AMDGPU FENCES"
      echo "============================================================"
      for f in /sys/kernel/debug/dri/*/amdgpu_fence_info; do
        [ -r "$f" ] || continue
        echo "--- $f ---"
        cat "$f" || true
      done
      echo

      echo "============================================================"
      echo "GPU PCIe STATE — 0c:00.0"
      echo "============================================================"
      lspci -vvnnk -s 0c:00.0 2>&1 || true
      echo

      echo "============================================================"
      echo "NVMe PCIe STATE — 01:00.0"
      echo "============================================================"
      lspci -vvnnk -s 01:00.0 2>&1 || true
      echo

      echo "============================================================"
      echo "RECENT KERNEL WARNINGS/ERRORS"
      echo "============================================================"
      dmesg --ctime \
        --level=emerg,alert,crit,err,warn \
        2>&1 \
        | tail -n 300 || true
      echo
    } > "$tmp" 2>&1

    # Atomic replacement: we never leave state-last.txt half-written.
    mv -f "$tmp" "$out"

    # This is intentionally aggressive while debugging crashes.
    # Ask the filesystem to commit the snapshot.
    sync -f "$dir" || true
  '';

  # --------------------------------------------------------------------------
  # Continuous /dev/kmsg recorder.
  #
  # dmesg first dumps the existing kernel ring buffer, then follows it.
  # One file is created per boot ID.
  # --------------------------------------------------------------------------
  kmsgScript = pkgs.writeShellScript "crash-monitor-kmsg" ''
    set -u

    dir="${logDir}"
    boot_id="$(cat /proc/sys/kernel/random/boot_id)"

    exec stdbuf -oL -eL \
      dmesg --follow --decode --ctime \
      >> "$dir/kmsg-$boot_id.log" 2>&1
  '';

  # --------------------------------------------------------------------------
  # After boot, automatically archive the PREVIOUS boot.
  #
  # Therefore after a crash + reboot, we don't need to remember any
  # journalctl commands. The evidence is already in /var/log/crash-monitor.
  # --------------------------------------------------------------------------
  archiveScript = pkgs.writeShellScript "crash-monitor-archive-previous" ''
    set -u

    dir="${logDir}"

    prev_boot="$(
      journalctl --list-boots --no-pager \
        | awk '$1 == "-1" { print $2; exit }'
    )"

    if [ -z "$prev_boot" ]; then
      exit 0
    fi

    base="$dir/previous-$prev_boot"

    # Full previous boot.
    journalctl \
      -b -1 \
      -o short-precise \
      --no-pager \
      > "$base-full.log" 2>&1 || true

    # Kernel only.
    journalctl \
      -b -1 \
      -k \
      -o short-precise \
      --no-pager \
      > "$base-kernel.log" 2>&1 || true

    # High-signal subset for the faults we are currently investigating.
    journalctl \
      -b -1 \
      -o short-precise \
      --no-pager \
      | grep -Ei \
        'amdgpu|drm|gpu|ring|kiq|kcq|fence|timeout|reset|fault|hang|lockup|watchdog|iommu|amd.?iommu|amd-vi|ivrs|pcie|aer|nvme|mce|ras|BUG:|WARNING:|Call Trace|panic|oops' \
      > "$base-focus.log" || true

    # Boot/shutdown history.
    last -x > "$base-last-x.log" 2>&1 || true

    # Preserve anything systemd-pstore recovered.
    if [ -d /var/lib/systemd/pstore ]; then
      mkdir -p "$base-pstore"
      cp -a /var/lib/systemd/pstore/. "$base-pstore/" 2>/dev/null || true
    fi

    # Also check the mounted pstore directly.
    if [ -d /sys/fs/pstore ]; then
      mkdir -p "$base-live-pstore"
      cp -a /sys/fs/pstore/. "$base-live-pstore/" 2>/dev/null || true
    fi

    sync -f "$dir" || true

    # Keep this temporary diagnostic directory bounded.
    find "$dir" \
      -maxdepth 1 \
      -type f \
      -mtime +14 \
      -delete || true
  '';

in
{
  # --------------------------------------------------------------------------
  # JOURNAL
  # --------------------------------------------------------------------------

  services.journald.extraConfig = ''
    Storage=persistent

    # Default is 5 minutes for ERR/WARNING/NOTICE/INFO/DEBUG.
    # During debugging, reduce the window of logs lost by abrupt power loss.
    SyncIntervalSec=5s

    # Do not let an AMDGPU/IOMMU error storm get rate-limited too quickly.
    RateLimitIntervalSec=30s
    RateLimitBurst=100000

    # Bound disk usage.
    SystemMaxUse=1G
    SystemKeepFree=2G
  '';

  # Larger printk ring buffer, useful when a driver dumps a large trace.
  boot.kernelParams = [
    "log_buf_len=16M"
  ];

  # --------------------------------------------------------------------------
  # HUNG-TASK DETECTION
  #
  # A task stuck in D-state for 30 seconds generates a kernel warning.
  # Do NOT panic/reboot; we want the diagnostic output.
  # --------------------------------------------------------------------------

  boot.kernel.sysctl = {
    "kernel.hung_task_timeout_secs" = 30;
    "kernel.hung_task_all_cpu_backtrace" = 1;
    "kernel.hung_task_panic" = 0;
  };

  # Persistent directory for our extra captures.
  systemd.tmpfiles.rules = [
    "d ${logDir} 0750 root root - -"
  ];

  # --------------------------------------------------------------------------
  # LIVE KERNEL LOG
  # --------------------------------------------------------------------------

  systemd.services.crash-monitor-kmsg = {
    description = "Continuous kernel crash log recorder";

    wantedBy = [ "multi-user.target" ];
    after = [
      "systemd-journald.service"
      "systemd-tmpfiles-setup.service"
    ];

    path = commonPath;

    serviceConfig = {
      Type = "simple";
      ExecStart = kmsgScript;

      Restart = "always";
      RestartSec = "2s";

      Nice = 19;
      IOSchedulingClass = "idle";
    };
  };

  # --------------------------------------------------------------------------
  # PERIODIC SYSTEM/GPU SNAPSHOT
  # --------------------------------------------------------------------------

  systemd.services.crash-monitor-snapshot = {
    description = "Capture crash diagnostic state";

    path = commonPath;

    serviceConfig = {
      Type = "oneshot";
      ExecStart = snapshotScript;

      Nice = 19;
      IOSchedulingClass = "idle";
    };
  };

  systemd.timers.crash-monitor-snapshot = {
    description = "Periodic crash diagnostic snapshot";

    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "30s";
      AccuracySec = "1s";
      Unit = "crash-monitor-snapshot.service";
    };
  };

  # --------------------------------------------------------------------------
  # AUTOMATIC PREVIOUS-BOOT ARCHIVE
  # --------------------------------------------------------------------------

  systemd.services.crash-monitor-archive-previous = {
    description = "Archive previous boot crash diagnostics";

    wantedBy = [ "multi-user.target" ];

    after = [
      "local-fs.target"
      "systemd-journal-flush.service"
      "systemd-pstore.service"
    ];

    path = commonPath;

    serviceConfig = {
      Type = "oneshot";
      ExecStart = archiveScript;

      Nice = 19;
      IOSchedulingClass = "idle";
    };
  };
}
