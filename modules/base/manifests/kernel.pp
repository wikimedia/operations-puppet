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
            'asn1_decoder',
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
            'macsec',
            'parport',
            'parport_pc',
            'ppdev',
            'acpi_power_meter',
            'bluetooth',
            'v4l2-common',
            'floppy',
            'cdrom',
            'binder_linux',
            'n_gsm',
            'algif_aead',
            'appletalk',
            'rxrpc',
            'nfc',
            'esp4',
            'esp6',
            'tipc',
            'atm',
            'slip',
            'slhc',
            'sctp',
        ],
    }

    # File systems not in use, blacklist as additional bandaid
    kmod::blacklist { 'wmf-filesystems':
        modules => [
            'btrfs',
            'erofs',
            'exfat',
            'f2fs',
            'hfs',
            'hfsplus',
            'jfs',
            'jffs2',
            'nilfs2',
            'orangefs',
            'squashfs',
        ],
    }

    # Network schedulers/packet mangling module we don't use or need
    kmod::blacklist { 'wmf-network-schedulers':
        modules => [
            'act_connmark',
            'act_pedit',
            'sch_red',
            'sch_taprio',
        ],
    }

    file { '/usr/local/bin/kernel-purge':
        ensure => file,
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
