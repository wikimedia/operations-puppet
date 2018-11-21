class openstack::serverpackages::mitaka::jessie(
) {
    # packages are installed from specific component profiles
    # turns out we are using the jessie-backports repo, which is added by default by ::apt
    file{'/etc/apt/preferences.d/openstack.pref':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/openstack/serverpackages/mitaka/jessie/openstack.pref',
    }
}

