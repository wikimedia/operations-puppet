class openstack::nova::common(
    $version,
    $region,
    $db_user,
    $db_pass,
    $db_host,
    $db_name,
    $db_name_api,
    Array[Stdlib::Fqdn] $openstack_controllers,
    Array[Stdlib::Fqdn] $rabbitmq_nodes,
    Stdlib::Fqdn $keystone_api_fqdn,
    $scheduler_filters,
    $ldap_user_pass,
    $rabbit_user,
    $rabbit_pass,
    $metadata_proxy_shared_secret,
    $compute_workers,
    Stdlib::Port $metadata_listen_port,
    Stdlib::Port $osapi_compute_listen_port,
    Boolean $is_control_node,
) {

    class { "openstack::nova::common::${version}::${::lsbdistcodename}": }

    file { '/etc/nova/policy.yaml':
        source  => "puppet:///modules/openstack/${version}/nova/common/policy.yaml",
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        require => Package['nova-common'],
    }

    file { '/etc/nova/nova.conf':
        content   => template("openstack/${version}/nova/common/nova.conf.erb"),
        owner     => 'nova',
        group     => 'nogroup',
        mode      => '0440',
        show_diff => false,
        require   => Package['nova-common'];
    }

    if debian::codename::ge('buster') {
        # The Buster version of the Rocky packages creates the nova user
        #  with a weird high-number uid.  Try to head it off by creating here
        #  ahead of time.
        group { 'nova':
            ensure => 'present',
            name   => 'nova',
            system => true,
        }

        user { 'nova':
            ensure     => 'present',
            name       => 'nova',
            comment    => 'nova system user',
            gid        => 'nova',
            home       => '/var/lib/nova',
            managehome => false,
            before     => Package['nova-common'],
            system     => true,
        }
    }

}
