# Config for openstack horizon
#
# Here, 'config' refers to local_settings.py as well
#  as a variety of policy files which affect which
#  UI elements are displayed to which users.
#
# Because we deploy Horizon from source, and because
# the OpenStack APIs are backwards-compatible, we typically
# deploy a newer version of Horizon than the other OpenStack services.
#
# That means we track two different version settings here:
#
#  $horizon_version: the actual version of Horizon that's running
#
#  $openstack_version: the version used for the other openstack
#   services on e.g. cloudcontrol1001.
#
# We need to know the value of $openstack_version so that we can
# pull the policy files that Horizon uses from the appropriate services
# and avoid having to duplicate them just for Horizon to consume.
#
# SPDX-License-Identifier: Apache-2.0
class openstack::horizon::config(
    String        $horizon_version,
    String        $openstack_version,
    Stdlib::Fqdn  $keystone_api_fqdn,
    Stdlib::Fqdn  $dhcp_domain,
    String        $instance_network_id,
    Stdlib::Host  $ldap_rw_host,
    String        $ldap_user_pass,
    Array[String] $all_regions,
    String        $puppet_git_repo_name,
    String        $secret_key,
    Stdlib::Fqdn  $webserver_hostname = 'horizon.wikimedia.org',
) {
    ensure_resource('file', '/etc/openstack-dashboard', {
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        force  => true,
    })

    file { '/etc/openstack-dashboard/local_settings.py':
        content => template("openstack/${horizon_version}/horizon/local_settings.py.erb"),
        mode    => '0444',
        owner   => 'root',
        notify  => Service['openstack-dashboard'],
        require => File['/etc/openstack-dashboard'],
    }

    file { '/etc/openstack-dashboard/nova_policy.yaml':
        source  => "puppet:///modules/openstack/${openstack_version}/nova/common/policy.yaml",
        owner   => 'root',
        mode    => '0444',
        notify  => Service['openstack-dashboard'],
        require => File['/etc/openstack-dashboard'],
    }

    file { '/etc/openstack-dashboard/keystone_policy.yaml':
        source  => "puppet:///modules/openstack/${openstack_version}/keystone/policy.yaml",
        owner   => 'root',
        mode    => '0444',
        notify  => Service['openstack-dashboard'],
        require => File['/etc/openstack-dashboard'],
    }

    file { '/etc/openstack-dashboard/glance_policy.yaml':
        source  => "puppet:///modules/openstack/${openstack_version}/glance/policy.yaml",
        owner   => 'root',
        mode    => '0444',
        notify  => Service['openstack-dashboard'],
        require => File['/etc/openstack-dashboard'],
    }

    file { '/etc/openstack-dashboard/designate_policy.yaml':
        source  => "puppet:///modules/openstack/${openstack_version}/designate/policy.yaml",
        owner   => 'root',
        mode    => '0444',
        notify  => Service['openstack-dashboard'],
        require => File['/etc/openstack-dashboard'],
    }

    file { '/etc/openstack-dashboard/neutron_policy.yaml':
        source  => "puppet:///modules/openstack/${openstack_version}/neutron/policy.yaml",
        owner   => 'root',
        mode    => '0444',
        notify  => Service['openstack-dashboard'],
        require => File['/etc/openstack-dashboard'],
    }

    file { '/etc/openstack-dashboard/cinder_policy.yaml':
        source  => "puppet:///modules/openstack/${openstack_version}/cinder/policy.yaml",
        owner   => 'root',
        mode    => '0444',
        notify  => Service['openstack-dashboard'],
        require => File['/etc/openstack-dashboard'],
    }

    file { '/etc/openstack-dashboard/trove_policy.yaml':
        source  => "puppet:///modules/openstack/${openstack_version}/trove/policy.yaml",
        owner   => 'root',
        mode    => '0444',
        notify  => Service['openstack-dashboard'],
        require => File['/etc/openstack-dashboard'],
    }

    # This is a trivial policy file that forbids everything.  We'll use it
    #  for services that we don't support to prevent Horizon from
    #  displaying spurious panels.
    file { '/etc/openstack-dashboard/disabled_policy.yaml':
        source  => "puppet:///modules/openstack/${horizon_version}/horizon/disabled_policy.yaml",
        owner   => 'root',
        mode    => '0444',
        notify  => Service['openstack-dashboard'],
        require => File['/etc/openstack-dashboard'],
    }
}
