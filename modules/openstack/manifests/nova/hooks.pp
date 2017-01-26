# Hook nova notification events for instance
#  page updates
class openstack::nova::hooks(
    $openstack_version  = $::openstack::version)
{
    require ::openstack
    if ! defined(Package['python-mwclient']) {
        package { 'python-mwclient':
            ensure => latest,
        }
    }

    file { '/usr/lib/python2.7/dist-packages/wikistatus':
        source  => "puppet:///modules/openstack/${openstack_version}/nova/wikistatus",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['python-mwclient'],
        recurse => true,
    }

    file { '/usr/lib/python2.7/dist-packages/wikistatus.egg-info':
        source  => "puppet:///modules/openstack/${openstack_version}/nova/wikistatus.egg-info",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['python-mwclient'],
        recurse => true,
    }
}
