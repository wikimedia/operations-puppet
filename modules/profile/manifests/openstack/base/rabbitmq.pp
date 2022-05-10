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
                outdir        => '/etc/rabbitmq/ssl',
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

    # https://www.rabbitmq.com/management.html
    # Needed for https://www.rabbitmq.com/management-cli.html
    rabbitmq::plugin { 'rabbitmq_management': }

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

    rabbitmq::plugin { 'rabbitmq_prometheus': }

    ferm::service { 'rabbitmq-internals':
        proto  => 'tcp',
        port   => '(4369 5671 5672 25672)',
        # TODO: change openstack_controllers to something else when we have dedicated rabbit nodes
        srange => "(@resolve((${openstack_controllers.join(' ')})))",
    }

    ferm::service { 'rabbitmq-nova-hosts':
        proto  => 'tcp',
        port   => '(5671 5672)',
        srange => "(${labs_hosts_range} ${labs_hosts_range_v6})",
    }

    ferm::service { 'rabbitmq-openstack-control':
        proto  => 'tcp',
        port   => '(5671 5672)',
        srange => "(@resolve((${openstack_controllers.join(' ')})))",
    }

    ferm::service { 'rabbitmq-designate':
        proto  => 'tcp',
        port   => '(5671 5672)',
        srange => "(@resolve((${designate_hosts.join(' ')})))",
    }

    ferm::service { 'rabbitmq-cinder-backup':
        proto  => 'tcp',
        port   => '(5671 5672)',
        srange => "(@resolve((${cinder_backup_nodes.join(' ')})))",
    }

    ferm::service { 'rabbitmq-cloud-vps-instances':
        proto  => 'tcp',
        port   => '(5671 5672)',
        srange => '$LABS_NETWORKS',
    }
}
