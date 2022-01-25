class profile::openstack::base::rabbitmq(
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::openstack_controllers'),
    $monitor_user = lookup('profile::openstack::base::rabbit_monitor_user'),
    $monitor_password = lookup('profile::openstack::base::rabbit_monitor_pass'),
    $cleanup_password = lookup('profile::openstack::base::rabbit_cleanup_pass'),
    $file_handles = lookup('profile::openstack::base::rabbit_file_handles'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::base::designate_hosts'),
    $labs_hosts_range = lookup('profile::openstack::base::labs_hosts_range'),
    $labs_hosts_range_v6 = lookup('profile::openstack::base::labs_hosts_range_v6'),
    $nova_rabbit_user = lookup('profile::openstack::base::nova::rabbit_user'),
    $nova_rabbit_password = lookup('profile::openstack::base::nova::rabbit_pass'),
    $rabbit_erlang_cookie = lookup('profile::openstack::base::rabbit_erlang_cookie'),
    Optional[String] $rabbit_cfssl_label = lookup('profile::openstack::base::rabbitmq::rabbit_cfssl_label', {default_value => undef}),
    Array[Stdlib::Fqdn] $cinder_backup_nodes    = lookup('profile::openstack::base::cinder::backup::nodes'),
){
    if $rabbit_cfssl_label {
        $cert_paths = profile::pki::get_cert(
            $rabbit_cfssl_label,
            $facts['networking']['fqdn'],
            {
                provide_chain => true,
                owner         => 'rabbitmq',
                group         => 'rabbitmq',
                require       => Package['rabbitmq-server'],
                before        => File['/etc/rabbitmq/rabbitmq.config'],
                notify        => Service['rabbitmq-server'],
            }
        )

        $rabbitmq_tls_key_file = $cert_paths['key']
        $rabbitmq_tls_cert_file = $cert_paths['chained']
        $rabbitmq_tls_ca_file = '/etc/ssl/certs/wmf-ca-certificates.crt'
    } else {
        $rabbitmq_tls_key_file = undef
        $rabbitmq_tls_cert_file = undef
        $rabbitmq_tls_ca_file = undef
    }

    class { '::rabbitmq':
        file_handles  => $file_handles,
        erlang_cookie => $rabbit_erlang_cookie,
        tls_cert_file => $rabbitmq_tls_cert_file,
        tls_key_file  => $rabbitmq_tls_key_file,
        tls_ca_file   => $rabbitmq_tls_ca_file,
    }
    contain '::rabbitmq'
    class{'::rabbitmq::plugins':}
    contain '::rabbitmq::plugins'

    file { '/etc/rabbitmq/rabbitmq-env.conf':
        owner   => 'rabbitmq',
        group   => 'rabbitmq',
        mode    => '0644',
        source  => 'puppet:///modules/profile/openstack/base/rabbitmq/rabbitmq-env.conf',
        require => Package['rabbitmq-server'],
        notify  => Service['rabbitmq-server'],
    }

    # We want this job to run on only one host; it doesn't matter which.
    class {'::rabbitmq::cleanup':
        password => $cleanup_password,
        enabled  => $::fqdn == $openstack_controllers[0],
    }
    contain '::rabbitmq::cleanup'

    class {'::openstack::nova::rabbit':
        username => $nova_rabbit_user,
        password => $nova_rabbit_password,
        require  => Class['::rabbitmq'],
    }
    contain '::openstack::nova::rabbit'

    rabbitmq::user{"${monitor_user}-rabbituser":
      username      => $monitor_user,
      password      => $monitor_password,
      administrator => true,
      require       => Class['::rabbitmq'],
    }

    class { '::profile::prometheus::rabbitmq_exporter':
        rabbit_monitor_username => $monitor_user,
        rabbit_monitor_password => $monitor_password,
    }
    contain '::profile::prometheus::rabbitmq_exporter'

    ferm::rule{'rabbit_for_designate':
        ensure => 'present',
        rule   =>  "saddr (@resolve((${join($designate_hosts,' ')})) @resolve((${join($designate_hosts,' ')}), AAAA))
                    proto tcp dport (5671 5672) ACCEPT;",
    }

    ferm::rule{'beam_nova':
        ensure => 'present',
        rule   =>  "saddr (${labs_hosts_range} ${labs_hosts_range_v6}) proto tcp dport (5672 56918) ACCEPT;",
    }

    ferm::rule { 'rabbit_for_standby_node':
        ensure => 'present',
        rule   => "saddr (@resolve((${join($openstack_controllers,' ')}))
                          @resolve((${join($openstack_controllers,' ')}), AAAA))
                   proto tcp dport (5671 5672) ACCEPT;",
    }

    # Rabbit uses epmd for clustering
    ferm::rule { 'epmd_for_rabbit':
        ensure => 'present',
        rule   => "saddr (@resolve((${join($openstack_controllers,' ')}))
                          @resolve((${join($openstack_controllers,' ')}), AAAA))
                   proto tcp dport 4369 ACCEPT;",
    }

    ferm::rule { 'rabbit_internode':
        ensure => 'present',
        rule   => "saddr (@resolve((${join($openstack_controllers,' ')}))
                          @resolve((${join($openstack_controllers,' ')}), AAAA))
                   proto tcp dport 25672 ACCEPT;",
    }

    # Allow labs instances to talk to rabbitmq.
    # We need this because Trove instances are orchestrated
    #  via rabbitmq.
    include network::constants
    $labs_networks = join($network::constants::labs_networks, ' ')

    ferm::service { 'rabbitmq-access-for-cloud-vps-instances':
        proto  => 'tcp',
        port   => '(5671 5672)',
        srange => "(${labs_networks})",
    }

    # cinder-backup requires access to rabbit
    ferm::rule { 'rabbit_for_cinder_backup_nodes':
        ensure => 'present',
        rule   => "saddr (@resolve((${join($cinder_backup_nodes,' ')}))
                          @resolve((${join($cinder_backup_nodes,' ')}), AAAA))
                   proto tcp dport (5671 5672) ACCEPT;",
    }
}
