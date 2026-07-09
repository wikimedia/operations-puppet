# SPDX-License-Identifier: Apache-2.0
# @summary
#   Runs lvmd, the node-local volume management daemon for TopoLVM, as a
#   systemd service. It remains absent unless device-classes are defined.
#   See T429325
#
# @param device_classes
#   Maps TopoLVM device-classes to this host's LVM volume groups, using the
#   format of the device-classes section of lvmd.yaml.
class profile::kubernetes::node::lvmd (
    Array[Profile::Kubernetes::Lvmd_device_class] $device_classes = lookup('profile::kubernetes::node::lvmd::device_classes', { default_value => [] }),
) {
    $ensure = $device_classes.empty ? {
        true    => 'absent',
        default => 'present',
    }

    $default_classes = $device_classes.filter |$dc| { $dc['default'] == true }
    if $default_classes.length > 1 {
        fail('profile::kubernetes::node::lvmd: only one device-class may be the default')
    }

    if $ensure == 'present' {
        apt::package_from_component { 'lvmd':
            component => 'component/topolvm',
        }
        Package['lvmd'] -> Systemd::Service['lvmd']
    } else {
        package { 'lvmd':
            ensure => absent,
        }
    }

    $lvmd_config = {
        'socket-name'    => '/run/topolvm/lvmd.sock',
        'device-classes' => $device_classes,
    }

    file { '/etc/topolvm':
        ensure => stdlib::ensure($ensure, 'directory'),
        force  => true,
    }

    file { '/etc/topolvm/lvmd.yaml':
        ensure  => stdlib::ensure($ensure, 'file'),
        content => to_yaml($lvmd_config),
        mode    => '0444',
        notify  => Service['lvmd'],
    }

    systemd::service { 'lvmd':
        ensure               => $ensure,
        content              => systemd_template('lvmd'),
        restart              => true,
        monitoring_enabled   => true,
        monitoring_notes_url => 'https://wikitech.wikimedia.org/wiki/Helm/Upstream_Charts/topolvm',
        team                 => 'Data Platform',
    }
}
