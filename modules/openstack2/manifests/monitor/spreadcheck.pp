# == Class: openstack::monitor::spreadcheck
# NRPE check to see if critical instances for a project
# are spread out enough among the labvirt* hosts
class openstack2::monitor::spreadcheck(
    $active,
    $nova_controller,
    $nova_user,
    $nova_password,
) {
    # monitoring::service doesn't take a bool
    if $active {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    # Script that checks how 'spread out' critical instances for a project
    # are. See T101635
    file { '/usr/local/bin/spreadcheck.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/openstack2/monitor/spreadcheck.py',
    }

    # Config file to check how spread out toollabs critical instances are
    file { '/usr/local/etc/spreadcheck-tools.yaml':
        ensure  => 'present',
        owner   => 'nagios',
        group   => 'nagios',
        mode    => '0400',
        content => template('openstack2/monitor/spreadcheck-tools.yaml.erb'),
    }

    nrpe::monitor_service { 'check-tools-spread':
        ensure       => $ensure,
        nrpe_command => '/usr/local/bin/spreadcheck.py --config /usr/local/etc/spreadcheck-tools.yaml',
        description  => 'Tool Labs instance distribution',
        require      => File[
            '/usr/local/bin/spreadcheck.py',
            '/usr/local/etc/spreadcheck-tools.yaml'
        ],
    }
}
