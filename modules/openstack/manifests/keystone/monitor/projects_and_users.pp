# == Class: openstack::keystone::monitor::projects_and_users
#
# NRPE checks to make sure that the right keystone projects
#  exist and that projects have the proper service users.

class openstack::keystone::monitor::projects_and_users(
    $active,
    $contact_groups='wmcs-bots,admins',
    ) {

    # monitoring::service doesn't take a bool
    if $active {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    # Script to check all keystone projects for a given user and role
    file { '/usr/local/bin/check_keystone_roles.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/openstack/monitor/keystone/check_keystone_roles.py',
    }

    # Script to make sure that service projects e.g. 'admin' exists
    file { '/usr/local/bin/check_keystone_projects.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/openstack/monitor/keystone/check_keystone_projects.py',
    }

    # Make sure 'novaobserver' has 'observer' everywhere
    nrpe::monitor_service { 'check-novaobserver-membership':
        ensure        => $ensure,
        nrpe_command  => '/usr/local/bin/check_keystone_roles.py novaobserver observer',
        description   => 'novaobserver has only observer role',
        require       => File['/usr/local/bin/check_keystone_roles.py'],
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }

    # Make sure 'novaadmin' has 'projectadmin' and 'user' everywhere
    nrpe::monitor_service { 'check-novaadmin-membership':
        ensure        => $ensure,
        nrpe_command  => '/usr/local/bin/check_keystone_roles.py novaadmin user projectadmin',
        description   => 'novaadmin has roles in every project',
        require       => File['/usr/local/bin/check_keystone_roles.py'],
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }

    # Verify service projects
    nrpe::monitor_service { 'check-keystone-projects':
        ensure        => $ensure,
        nrpe_command  => '/usr/local/bin/check_keystone_projects.py',
        description   => 'Keystone admin and observer projects exist',
        require       => File['/usr/local/bin/check_keystone_roles.py'],
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }

}
