class openstack::neutron::base {

    if os_version('debian == jessie') {

        file {'/etc/neutron/original':
            ensure  => 'directory',
            owner   => 'neutron',
            group   => 'neutron',
            mode    => '0755',
            recurse => true,
            source  => "puppet:///modules/openstack/${version}/neutron/original",
        }
    }
}
