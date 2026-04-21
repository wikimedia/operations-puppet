# SPDX-License-Identifier: Apache-2.0
# Class ganeti
#
# Install ganeti
#
# Parameters:
#   with_drbd: Boolean. Indicates if drbd should be configured. Defaults to true
#
# Actions:
#   Install ganeti and configure modules/LVM. Does NOT initialize a cluster
#
class ganeti(
    Boolean $with_drbd=true,
) {
    ensure_packages('qemu-system-x86')

    # Setup Kernel Same-page Merging to save memory via memory deduplication
    sysfs::parameters { 'ksm':
        values => {
            'kernel/mm/ksm/run'             => '0',
            'kernel/mm/ksm/sleep_millisecs' => '100',
        },
    }

    ensure_packages('ganeti')

    service { 'ganeti':
        ensure => running,
    }

    # We're not using ganeti-instance-debootstrap to create images (we PXE-boot
    # the same images we use for baremetal servers), but /usr/share/ganeti/os/debootstrap
    # is needed as an OS provider for "gnt-instance add"
    ensure_packages(['drbd-utils', 'ovmf', 'ganeti-instance-debootstrap'])

    if $with_drbd {
        kmod::options { 'drbd':
            options => 'minor_count=128 usermode_helper=/bin/true',
        }

        # Enable drbd
        kmod::module { 'drbd':
            ensure => 'present',
        }

        # Disable the systemd service shipped with the drbd package. Ganeti handles
        # DRBD on its own
        service { 'drbd':
            ensure => 'stopped',
            enable => false,
        }
    }

    # Enable vhost_net
    kmod::module { 'vhost_net':
        ensure => 'present',
    }

    # lvm.conf
    # Note: We deviate from the default lvm.conf to change the filter config to
    # not include all block devices. TODO: Do it via augeas
    file { '/etc/lvm/lvm.conf' :
        ensure => present,
        mode   => '0644',
        source => 'puppet:///modules/ganeti/lvm.conf',
    }

    file { '/usr/local/sbin/setup-ganeti-lvm' :
        ensure => present,
        mode   => '0555',
        source => 'puppet:///modules/ganeti/setup-ganeti-lvm.py',
    }

    file { '/usr/local/sbin/validate-ganeti-firewall' :
        ensure => present,
        mode   => '0555',
        source => 'puppet:///modules/ganeti/validate-ganeti-firewall.sh',
    }

}
