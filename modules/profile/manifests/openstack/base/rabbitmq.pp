class profile::openstack::base::rabbitmq(
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    $monitor_user = hiera('profile::openstack::base::rabbit_monitor_user'),
    $monitor_password = hiera('profile::openstack::base::rabbit_monitor_pass'),
    $monitoring_host = hiera('profile::openstack::base::monitoring_host'),
    $cleanup_password = hiera('profile::openstack::base::rabbit_cleanup_pass'),
    $file_handles = hiera('profile::openstack::base::rabbit_file_handles'),
    $nova_api_host = hiera('profile::openstack::base::nova_api_host'),
    $designate_host = hiera('profile::openstack::base::designate_host'),
    $labs_hosts_range = hiera('profile::openstack::base::labs_hosts_range'),
    $nova_rabbit_user = hiera('profile::openstack::base::nova::rabbit_user'),
    $nova_rabbit_password = hiera('profile::openstack::base::nova::rabbit_pass'),
){

    class { '::rabbitmq':
        file_handles => $file_handles,
    }
    contain '::rabbitmq'
    class{'::rabbitmq::plugins':}
    contain '::rabbitmq::plugins'

    class {'::rabbitmq::cleanup':
        password => $cleanup_password,
        enabled  => $::fqdn == $nova_controller,
    }
    contain '::rabbitmq::cleanup'

    class {'::openstack::nova::rabbit':
        username => $nova_rabbit_user,
        password => $nova_rabbit_password,
        require  => Class['::rabbitmq'],
    }
    contain '::openstack::nova::rabbit'

    class { '::rabbitmq::monitor':
        rabbit_monitor_username => $monitor_user,
        rabbit_monitor_password => $monitor_password,
    }
    contain '::rabbitmq::monitor'

    # Need to package this for Jessie (T188392)
    if os_version('ubuntu == trusty') {
        class { '::profile::prometheus::rabbitmq_exporter':
            prometheus_nodes        => $monitoring_host,
            rabbit_monitor_username => $monitor_user,
            rabbit_monitor_password => $monitor_password,
        }
        contain '::profile::prometheus::rabbitmq_exporter'
    }

    ferm::rule{'rabbit_for_designate':
        ensure => 'present',
        rule   =>  "saddr @resolve(${designate_host}) proto tcp dport 5672 ACCEPT;",
    }

    ferm::rule{'rabbit_for_nova_api':
        ensure => 'present',
        rule   =>  "saddr @resolve(${nova_api_host}) proto tcp dport 5672 ACCEPT;",
    }

    ferm::rule{'beam_nova':
        ensure => 'present',
        rule   =>  "saddr ${labs_hosts_range} proto tcp dport (5672 56918) ACCEPT;",
    }
}
