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
# Requires:
#
# Sample Usage
#   include ganeti
class ganeti(
    $with_drbd=true
    ) {
    include ganeti::kvm

    package { [
            'ganeti',
            'ganeti-instance-debootstrap',
            'drbd8-utils',
            ] :
        ensure => installed,
    }

    if $with_drbd {
        file { '/etc/modprobe.d/drbd.conf':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            content => "options drbd minor_count=128 usermode_helper=/bin/true\n",
        }

        # Enable drbd
        exec { 'enable-module-drbd':
            unless  => "/bin/grep -q '^drbd$' /etc/modules",
            command => '/bin/echo drbd >> /etc/modules',
        }
        exec { 'load-module-drbd' :
            unless  => "/bin/lsmod | /bin/grep -q '^drbd'",
            command => '/sbin/modprobe drbd',
        }
        # Disable the systemd service shipped with drbd8-utils. Ganeti handles
        # DRBD on its own
        service { 'drbd':
            ensure => 'stopped',
            enable => false,
        }
    }
    # Enable vhost_net
    exec { 'enable-module-vhost_net' :
        unless  => "/bin/grep -q '^vhost_net$' /etc/modules",
        command => '/bin/echo vhost_net >> /etc/modules',
    }
    exec { 'load-module-vhost_net' :
        unless  => "/bin/lsmod | /bin/grep -q '^vhost_net'",
        command => '/sbin/modprobe vhost_net',
    }

    # lvm.conf
    # Note: We deviate from the default lvm.conf to change the filter config to
    # not include all block devices. TODO: Do it via augeas
    file { '/etc/lvm/lvm.conf' :
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/ganeti/lvm.conf',
    }
}
