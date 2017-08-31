# Hook keystone notification events for custom
#  project swizzling
class openstack2::keystone::hooks(
    $version,
    ) {
    include openstack2::keystone::service

    file { '/usr/lib/python2.7/dist-packages/designatemakedomain.py':
        source => "puppet:///modules/openstack2/${openstack_version}/admin_scripts/makedomain",
        owner  => 'root',
        group  => 'root',
        mode   => '0744',
    }

    file { '/usr/lib/python2.7/dist-packages/wmfkeystonehooks':
        source  => "puppet:///modules/openstack/${version}/keystone/wmfkeystonehooks",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        recurse => true,
        notify  => Service['keystone'],
    }

    file { '/usr/lib/python2.7/dist-packages/wmfkeystonehooks.egg-info':
        source  => "puppet:///modules/openstack/${version}/keystone/wmfkeystonehooks.egg-info",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        recurse => true,
        notify  => Service['keystone'],
    }
}
