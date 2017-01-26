# Hook keystone notification events for custom
#  project swizzling
class openstack::keystone::hooks(
    $openstack_version  = $::openstack::version)
{
    file { '/usr/lib/python2.7/dist-packages/wmfkeystonehooks':
        source  => "puppet:///modules/openstack/${openstack_version}/keystone/wmfkeystonehooks",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Service['keystone'],
        recurse => true,
    }
    file { '/usr/lib/python2.7/dist-packages/wmfkeystonehooks.egg-info':
        source  => "puppet:///modules/openstack/${openstack_version}/keystone/wmfkeystonehooks.egg-info",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Service['keystone'],
        recurse => true,
    }
}

