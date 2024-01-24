# == Class: base::kernel
#
# Settings related to the Linux kernel and microcode loading
#
# [*overlayfs*]
#  bool for whether overlay module is needed

class base::kernel(
    $overlayfs,
    ) {
    if ! $overlayfs {
        kmod::blacklist { 'wmf_overlay':
            modules => [
                'overlayfs',
                'overlay',
            ],
        }
    } else {
        kmod::blacklist { 'wmf_overlay':
            ensure => absent,
        }

        # On a fresh node overlay may be unloaded automatically by the OS
        # if no fs needs it. In this case the kern.log should look like:
        # kernel: request_module fs-overlay succeeded, but still no fs?
        # This may lead to unwanted side effects, like Docker not finding
        # the overlay kernel module loaded and falling back to
        # the device-mapper storage driver.
        # Therefore we explicitly load the overlay module when the overlayfs
        # option is true.
        kmod::module { 'overlay':
            ensure => 'present',
        }
    }

    kmod::blacklist { 'wmf':
        modules => [
            'aufs',
            'usbip-core',
            'usbip-host',
            'vhci-hcd',
            'dccp',
            'dccp_ipv6',
            'dccp_ipv4',
            'dccp_probe',
            'dccp_diag',
            'n_hdlc',
            'intel_cstate',
            'intel_rapl_perf',
            'intel_uncore',
            'parport',
            'parport_pc',
            'ppdev',
            'acpi_power_meter',
            'bluetooth',
            'v4l2-common',
            'floppy',
            'cdrom',
            'binder_linux',
        ],
    }

    # File systems not in use, blacklist as additonal bandaid
    kmod::blacklist { 'wmf-filesystems':
        modules => [
            'exfat',
            'f2fs',
        ],
    }

    if (versioncmp($::kernelversion, '4.4') >= 0) {
        kmod::blacklist { 'linux44':
            modules => [ 'asn1_decoder', 'macsec' ],
        }
    }

    # This section is for blacklisting modules per server model.
    # It was originally started for acpi_pad issues on R320 (T162850)
    # but is meant to be extended as needed.
    case $::productname {
      'PowerEdge R320': {
        kmod::blacklist { 'r320':
            modules => [ 'acpi_pad' ],
        }
      }
      default: {}
    }

    nrpe::plugin { 'check_microcode':
        source => 'puppet:///modules/base/check-microcode.py',
    }

    nrpe::monitor_service { 'cpu_microcode_status':
        ensure         => 'present',
        description    => 'Check whether microcode mitigations for CPU vulnerabilities are applied',
        nrpe_command   => '/usr/local/lib/nagios/plugins/check_microcode',
        contact_group  => 'admins',
        check_interval => 1440,
        retry_interval => 5,
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Microcode',
    }

    # Only Debian Bullseye or newer has the autoremove logic
    if debian::codename::ge('bullseye') {
        file { '/usr/local/bin/kernel-purge':
            ensure => file,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
            source => 'puppet:///modules/base/kernel/kernel-purge.sh',
        }

        systemd::timer::job { 'kernel-purge':
            ensure      => present,
            description => 'Purge unused kernels',
            user        => 'root',
            command     => '/usr/local/bin/kernel-purge -p',
            interval    => {'start' => 'OnCalendar', 'interval' => 'monthly'},
        }
    }
}
