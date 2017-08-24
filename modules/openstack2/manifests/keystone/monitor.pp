# == Class: openstack::keystone::monitor
# NRPE checks to make sure that the right keystone projects
#  exist and that projects have the proper service users.
#
# This also checks the functionality of the keystone API generally.

class openstack2::keystone::monitor(
    $active,
    $auth_port,
    $public_port,
    ) {

    # monitoring::service doesn't take a bool
    if $active {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    monitoring::service { "keystone-http-${auth_port}":
        ensure        => $ensure,
        description   => "keystone admin endpoint port ${auth_port}",
        check_command => "check_http_on_port!${auth_port}",
    }

    monitoring::service { "keystone-http-${public_port}": # v2 api is limited here
        ensure        => $ensure,
        description   => "keystone public endoint port ${public_port}",
        check_command => "check_http_on_port!${public_port}",
    }

    # Make sure 'novaobserver' has 'observer' everywhere
    nrpe::monitor_service { 'check-novaobserver-membership':
        ensure       => $ensure,
        nrpe_command => '/usr/local/bin/check_keystone_roles.py novaobserver observer',
        description  => 'novaobserver has only observer role',
        require      => File['/usr/local/bin/check_keystone_roles.py'],
    }

    # Make sure 'novaadmin' has 'projectadmin' and 'user' everywhere
    nrpe::monitor_service { 'check-novaadmin-membership':
        ensure       => $ensure,
        nrpe_command => '/usr/local/bin/check_keystone_roles.py novaadmin user projectadmin',
        description  => 'novaadmin has roles in every project',
        require      => File['/usr/local/bin/check_keystone_roles.py'],
    }

    # Verify service projects
    nrpe::monitor_service { 'check-keystone-projects':
        ensure       => $ensure,
        nrpe_command => '/usr/local/bin/check_keystone_projects.py',
        description  => 'Keystone admin and observer projects exist',
        require      => File['/usr/local/bin/check_keystone_roles.py'],
    }

    # Script to check all keystone projects for a given user and role
    file { '/usr/local/bin/check_keystone_roles.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/openstack/check_keystone_roles.py',
    }

    # Script to make sure that service projects e.g. 'admin' exists
    file { '/usr/local/bin/check_keystone_projects.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/openstack/check_keystone_projects.py',
    }

}
