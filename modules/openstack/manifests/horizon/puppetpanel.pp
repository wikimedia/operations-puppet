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
        require => Package['openstack-dashboard'],
        notify  => Exec['djangorefresh'],
        recurse => true,
    }
    file { '/usr/share/openstack-dashboard/openstack_dashboard/local/enabled/_1923_puppet_group_add.py':
        source  => "puppet:///modules/openstack/${openstack_version}/horizon/puppet_group_add.py",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Exec['djangorefresh'],
        require => Package['openstack-dashboard'],
    }
    file { '/usr/share/openstack-dashboard/openstack_dashboard/local/enabled/_1924_puppet_project_panel.py':
        source  => "puppet:///modules/openstack/${openstack_version}/horizon/puppet_tab_enable.py",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Exec['djangorefresh'],
        require => Package['openstack-dashboard'],
    }
    file { '/usr/share/openstack-dashboard/openstack_dashboard/local/enabled/_1925_puppet_prefix_panel.py':
        source  => "puppet:///modules/openstack/${openstack_version}/horizon/puppet_prefix_tab_enable.py",
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Exec['djangorefresh'],
        require => Package['openstack-dashboard'],
    }
}
