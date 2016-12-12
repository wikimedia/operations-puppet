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
        check_command => 'keystonerolecheck!novaobserver!observer"
    }

    # Make sure novaadmin is in every project with 'user' and 'projectadmin'
    monitoring::service { 'novaobserver project roles':
        description   => 'novaobserver has only observer role',
        check_command => 'keystonerolecheck!novaadmin!user|projectadmin"
    }
}
