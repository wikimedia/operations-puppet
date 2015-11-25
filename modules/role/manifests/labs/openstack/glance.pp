class role::labs::openstack::glance::server {

    system::role { $name: }

    $keystone_host   = hiera('labs_keystone_host')
    $glanceconfig    = hiera_hash('glanceconfig', {})
    $keystoneconfig  = hiera_hash('keystoneconfig', {})

    $glanceconfig['auth_uri']               = "http://${keystone_host}:5000"
    $glanceconfig['keystone_auth_host']     = ipresolve($keystone_host,4)
    $glanceconfig['keystone_auth_port']     = $keystoneconfig['auth_port']
    $glanceconfig['keystone_admin_token']   = $keystoneconfig['admin_token']
    $glanceconfig['keystone_auth_protocol'] = $keystoneconfig['auth_protocol']

    class { 'openstack::glance::service':
        glanceconfig      => $glanceconfig,
    }
}
