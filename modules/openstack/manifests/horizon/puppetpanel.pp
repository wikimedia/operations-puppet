# Install a custom-for-wikimedia Horizon panel
#  to manage instance puppet configuration
class openstack::horizon::puppetpanel(
    $openstack_version  = $::openstack::version)
{
    file { '/usr/lib/python2.7/dist-packages/wikimediapuppettab':
        source  => "puppet:///modules/openstack/${openstack_version}/horizon/puppettab",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['python-designate-dashboard', 'openstack-dashboard'],
        notify  => Exec['djangorefresh'],
        recurse => true
    }
    file { '/usr/share/openstack-dashboard/openstack_dashboard/local/enabled/_1923_puppet_role_panel.py':
        source  => "puppet:///modules/openstack/${openstack_version}/horizon/puppet_tab_enable.py",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Exec['djangorefresh'],
        require => Package['python-designate-dashboard', 'openstack-dashboard'],
    }
}
