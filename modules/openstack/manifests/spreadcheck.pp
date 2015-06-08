# == Class: openstack::spreadcheck
# NRPE check to see if critical instances for a project
# are spread out enough among the labvirt* hosts
class openstack::spreadcheck(
    $novaconfig,
) {
    include passwords::openstack::nova

    $nova_password = $passwords::openstack::nova::nova_ldap_user_pass
    $nova_controller_hostname = $novaconfig['controller_hostname']
    $nova_region = $::site

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
        ensure => present,
        source => 'puppet:///modules/openstack/spreadcheck-tools.yaml',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { '/usr/local/bin/spreadcheck.bash':
        ensure  => present,
        content => template('openstack/spreadcheck.bash.erb'),
        mode    => '0700', # has passwords!
        owner   => 'nagios',
        group   => 'nagios',
    }

    nrpe::monitor_service { 'check-tools-spread':
        nrpe_command => '/usr/local/bin/spreadcheck.bash --config /usr/local/etc/spreadcheck-tools.yaml',
        description  => 'Check if Tool Labs instances are spread out enough on labvirt**** hosts',
        require      => File[
            '/usr/local/bin/spreadcheck.py',
            '/usr/local/etc/spreadcheck-tools.yaml',
            '/usr/local/bin/spreadcheck.bash',
        ],
    }
}
