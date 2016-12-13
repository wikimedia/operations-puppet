class role::labs::openstack::keystone::server {

    system::role { $name: }

    $nova_controller   = hiera('labs_nova_controller')
    $keystoneconfig    = hiera_hash('keystoneconfig', {})

    class { 'openstack::keystone::service':
        keystoneconfig => $keystoneconfig,
    }

    # Monitor project membership
    include ::openstack::clientlib

    # Make sure novaobserver is in every project and only has observer rights
    monitoring::service { 'novaobserver project roles':
        description   => 'novaobserver has only observer role',
        check_command => 'check_keystone_roles!novaobserver!observer',
    }

    # Make sure novaadmin is in every project with 'user' and 'projectadmin'
    monitoring::service { 'novaadmin project roles':
        description   => 'novaadmin has roles in every project',
        check_command => 'check_keystone_roles!novaadmin!user!projectadmin',
    }

    # Make sure keystone admin and observer projects exist, and that
    #  keystone project ids == keystone project names
    monitoring::service { 'keystone projects exist':
        description   => 'Keystone admin and observer roles exist',
        check_command => 'check_keystone_projects',
    }
}
