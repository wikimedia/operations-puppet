# == Class: openstack::spreadcheck
# NRPE check to see if critical instances for a project
# are spread out enough among the labvirt* hosts
class openstack::spreadcheck(
    $novaconfig,
) {

    include passwords::labs::toollabs

    $nova_user = $passwords::labs::toollabs::nova_user
    $nova_password = $passwords::labs::toollabs::nova_password
    $nova_controller_hostname = $novaconfig['controller_hostname']

    # Script that checks how 'spread out' critical instances for a project
    # are. See T101635
    file { '/usr/local/bin/spreadcheck.py':
        ensure => present,
        source => 'puppet:///modules/openstack/spreadcheck.py',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    # Config file to check how spread out toollabs critical instances are
    file { '/usr/local/etc/spreadcheck-tools.yaml':
        ensure  => present,
        content => template('openstack/spreadcheck-tools.yaml.erb'),
        mode    => '0400',
        owner   => 'nagios',
        group   => 'nagios',
    }

    nrpe::monitor_service { 'check-tools-spread':
        nrpe_command => '/usr/local/bin/spreadcheck.py --config /usr/local/etc/spreadcheck-tools.yaml',
        description  => 'Tool Labs instance distribution',
        require      => File[
            '/usr/local/bin/spreadcheck.py',
            '/usr/local/etc/spreadcheck-tools.yaml'
        ],
    }
}
