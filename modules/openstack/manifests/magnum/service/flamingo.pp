# SPDX-License-Identifier: Apache-2.0

class openstack::magnum::service::flamingo(
    String $db_user,
    String $region,
    Array[Stdlib::Fqdn] $memcached_nodes,
    Array[Stdlib::Fqdn] $rabbitmq_nodes,
    String $db_pass,
    String $db_name,
    Stdlib::Fqdn $db_host,
    Stdlib::Fqdn $etcd_discovery_host,
    String $ldap_user_pass,
    Stdlib::Fqdn $keystone_fqdn,
    Stdlib::Port $api_bind_port,
    String $rabbit_user,
    String $rabbit_pass,
    String $domain_admin_pass,
    String $magnum_driver,
    Stdlib::HTTPSUrl $helm_chart_repo,
) {
    package { 'magnum-api':
        ensure => 'present',
    }
    package { 'magnum-conductor':
        ensure => 'present',
    }
    if $magnum_driver == 'capi_helm' {
        package { 'python3-magnum-capi-helm':
            ensure => 'present',
        }
        package { 'helm3':
            ensure => 'present',
        }
        package { 'magnum-cluster-api':
            ensure => 'absent',
        }
    } elsif $magnum_driver == 'cluster_api' {
        package { 'python3-magnum-capi-helm':
            ensure => 'absent',
        }
        package { 'helm3':
            ensure => 'absent',
        }
        package { 'magnum-cluster-api':
            ensure => 'present',
        }
    }

    $version = inline_template("<%= @title.split(':')[-1] -%>")
    $keystone_auth_username = 'magnum'
    $keystone_auth_project = 'service'
    $etcd_discovery_url = "https://${etcd_discovery_host}"
    file {
        '/etc/magnum/magnum.conf':
            content   => template('openstack/flamingo/magnum/magnum.conf.erb'),
            owner     => 'magnum',
            group     => 'magnum',
            mode      => '0440',
            show_diff => false,
            notify    => Service['magnum-api', 'magnum-conductor'],
            require   => Package['magnum-api', 'magnum-conductor'];
        '/etc/magnum/policy.yaml':
            source  => 'puppet:///modules/openstack/flamingo/magnum/policy.yaml',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['magnum-api', 'magnum-conductor'],
            require => Package['magnum-api', 'magnum-conductor'];
        '/etc/init.d/magnum-api':
            content => template('openstack/flamingo/magnum/magnum-api.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
    }
}
