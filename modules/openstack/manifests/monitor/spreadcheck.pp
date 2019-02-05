# == Class: openstack::monitor::spreadcheck
# NRPE check to see if critical instances for a project
# are spread out enough among the labvirt* hosts
class openstack::monitor::spreadcheck(
    $active,
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
    file { '/usr/local/sbin/wmcs-spreadcheck':
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/openstack/monitor/wmcs-spreadcheck.py',
    }

    # Config file to check how spread out toolforge critical instances are
    file { '/etc/wmcs-spreadcheck-tools.yaml':
        ensure => $ensure,
        owner  => 'nagios',
        group  => 'nagios',
        mode   => '0400',
        source => 'puppet:///modules/openstack/monitor/wmcs-spreadcheck-tools.yaml',
    }

    nrpe::monitor_service { 'check-tools-spread':
        ensure       => $ensure,
        nrpe_command => '/usr/local/sbin/wmcs-spreadcheck --config /etc/wmcs-spreadcheck-tools.yaml',
        description  => 'Toolforge instance distribution',
        require      => File[
            '/usr/local/sbin/wmcs-spreadcheck',
            '/etc/wmcs-spreadcheck-tools.yaml'
        ],
    }

    # renaming cleanup
    $files = [
        '/usr/local/bin/spreadcheck.py',
        '/usr/local/etc/spreadcheck-tools.yaml',
    ]

    file { $files:
        ensure => 'absent',
    }
}
