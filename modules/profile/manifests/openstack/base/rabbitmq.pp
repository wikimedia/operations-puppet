class profile::openstack::base::rabbitmq(
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    $monitor_user = hiera('profile::openstack::base::rabbit_monitor_user'),
    $monitor_password = hiera('profile::openstack::base::rabbit_monitor_pass'),
    $monitoring_host = hiera('profile::openstack::base::monitoring_host'),
    $file_handles = hiera('profile::openstack::base::rabbit_file_handles'),
    $nova_api_host = hiera('profile::openstack::base::nova_api_host'),
    $designate_host = hiera('profile::openstack::base::designate_host'),
    $labs_hosts_range = hiera('profile::openstack::base::labs_hosts_range'),
){

    class { '::rabbitmq':
        running      => $::fqdn == $nova_controller,
        file_handles => $file_handles,
    }
    contain '::rabbitmq'

    class { '::rabbitmq::monitor':
        rabbit_monitor_username => $monitor_user,
        rabbit_monitor_password => $monitor_password,
    }
    contain '::rabbitmq::monitor'

    class ['::profile::prometheus::rabbitmq_exporter':
        prometheusnodes  => $monitoring_host,
        monitor_user     => $monitor_user,
        monitor_password => $monitor_password,
     }
     contain '::profile::prometheus::rabbitmq_exporter'

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

    # These logfiles will be rotated by an already-existing wildcard logrotate rule for rabbit
    cron {
        'drain and log rabbit notifications.error queue':
            ensure  => 'present',
            user    => 'root',
            minute  => '35',
            command => '/usr/local/sbin/drain_queue notifications.error >> /var/log/rabbitmq/notifications_error.log 2>&1',
    }
}
