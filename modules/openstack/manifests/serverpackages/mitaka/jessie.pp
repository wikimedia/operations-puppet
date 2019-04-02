class openstack::serverpackages::mitaka::jessie(
) {
    require openstack::commonpackages::mitaka

    apt::pin { 'openstack-serverpackages-mitaka-jessie':
        package  => 'python-warlok python-jsonschema python-funcsigs',
        pin      => 'release c=openstack-mitaka-jessie',
        priority => '2001',
    }
}

