# @summary Cloud VPS OpenStack RabbitMQ message queue server
# @param rabbitmq_service_name The name that clients use to connect to this server. Usually in the
#   form of rabbitmqNN.DEPLOYMENT.wikimediacloud.org.
# @param rabbitmq_own_name The name that this node is internally known in the cluster. Usually
#   either rabbitmq_service_name or the node cloud-private address.
#
# There are two similarly-named params here, '$rabbitmq_setup_nodes' and '$rabbitmq_nodes':
#
#  $rabbitmq_nodes is the list of nodes that rabbitmq clients should actually use; it will generally
#   consist of wikimediacloud.org service names rather than physical hardware fqdns. These values
#   will be baked into unpuppetized Trove VMs and so should be changed as little as possible; changes
#   to active rabbit nodes should be made via dns changes to the service fqdns.
#
#  $rabbitmq_setup_nodes is a list of fqdns of hosts that are configured by this class but not yet
#   in service. It exists to stage new rabbitmq nodes (with firewalls and such) before switching
#   traffic over. It should consist of primary fqdns (.wikimedia.org or .wmnet)
#
class profile::openstack::base::rabbitmq(
    Array[Stdlib::Fqdn] $rabbitmq_nodes = lookup('profile::openstack::base::rabbitmq_nodes'),
    Array[Stdlib::Fqdn] $rabbitmq_setup_nodes = lookup('profile::openstack::base::rabbitmq_setup_nodes'),
    Stdlib::Fqdn $rabbitmq_service_name = lookup('profile::openstack::base::rabbitmq_service_name'),
    Stdlib::Fqdn $rabbitmq_own_name = lookup('profile::openstack::base::rabbitmq::rabbitmq_own_name'),
    $monitor_user = lookup('profile::openstack::base::rabbit_monitor_user'),
    $monitor_password = lookup('profile::openstack::base::rabbit_monitor_pass'),
    $cleanup_password = lookup('profile::openstack::base::rabbit_cleanup_pass'),
    $file_handles = lookup('profile::openstack::base::rabbit_file_handles'),
    String $nova_rabbit_user = lookup('profile::openstack::base::nova::rabbit_user'),
    String $nova_rabbit_password = lookup('profile::openstack::base::nova::rabbit_pass'),
    String $neutron_rabbit_user = lookup('profile::openstack::base::neutron::rabbit_user'),
    String $neutron_rabbit_password = lookup('profile::openstack::base::neutron::rabbit_pass'),
    String $trove_guest_rabbit_user = lookup('profile::openstack::base::trove::trove_guest_rabbit_user'),
    String $trove_guest_rabbit_pass = lookup('profile::openstack::base::trove::trove_guest_rabbit_pass'),
    String $heat_rabbit_user = lookup('profile::openstack::base::heat::rabbit_user'),
    String $heat_rabbit_password = lookup('profile::openstack::base::heat::rabbit_pass'),
    String $magnum_rabbit_user = lookup('profile::openstack::base::magnum::rabbit_user'),
    String $magnum_rabbit_password = lookup('profile::openstack::base::magnum::rabbit_pass'),
    $rabbit_erlang_cookie = lookup('profile::openstack::base::rabbit_erlang_cookie'),
    Optional[String] $rabbit_cfssl_label = lookup('profile::openstack::base::rabbitmq::rabbit_cfssl_label', {default_value => undef}),
    Integer $heartbeat_timeout = lookup('profile::openstack::base::heartbeat_timeout'),
    String $version = lookup('profile::openstack::base::version'),
    Stdlib::IP::Address::V4 $cloud_private_supernet = lookup('profile::wmcs::cloud_private_subnet::supernet'),
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
                hosts         => [
                    $facts['networking']['fqdn'],
                    $rabbitmq_service_name,
                    $rabbitmq_own_name,
                ].unique(),
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
        file_handles      => $file_handles,
        erlang_cookie     => $rabbit_erlang_cookie,
        tls_cert_file     => $rabbitmq_tls_cert_file,
        tls_key_file      => $rabbitmq_tls_key_file,
        tls_ca_file       => $rabbitmq_tls_ca_file,
        heartbeat_timeout => $heartbeat_timeout,
    }
    contain '::rabbitmq'

    # https://www.rabbitmq.com/management.html
    # Needed for https://www.rabbitmq.com/management-cli.html
    rabbitmq::plugin { 'rabbitmq_management': }

    # This installs some things we don't need but also sets up
    #  the versioned repo which will get us the latest version-specific
    #  rabbitmq packages
    class { "openstack::serverpackages::${version}::${::lsbdistcodename}":
    }

    file { '/etc/rabbitmq/rabbitmq-env.conf':
        owner   => 'rabbitmq',
        group   => 'rabbitmq',
        mode    => '0644',
        content => template('profile/openstack/base/rabbitmq/rabbitmq-env.conf.erb'),
        require => Package['rabbitmq-server'],
        notify  => Service['rabbitmq-server'],
    }

    # We want this job to run on only one host; it doesn't matter which.
    class {'::rabbitmq::cleanup':
        password => $cleanup_password,
        enabled  => $rabbitmq_nodes[0] == $rabbitmq_service_name,
    }
    contain '::rabbitmq::cleanup'

    class { '::openstack::nova::rabbit':
        username => $nova_rabbit_user,
        password => $nova_rabbit_password,
    }

    class { '::openstack::neutron::rabbit':
        username => $neutron_rabbit_user,
        password => $neutron_rabbit_password,
    }

    class { '::openstack::heat::rabbit':
        username => $heat_rabbit_user,
        password => $heat_rabbit_password,
    }

    class { '::openstack::magnum::rabbit':
        username => $magnum_rabbit_user,
        password => $magnum_rabbit_password,
    }

    class { '::openstack::trove::rabbit':
        guest_username => $trove_guest_rabbit_user,
        guest_password => $trove_guest_rabbit_pass,
    }

    rabbitmq::plugin { 'rabbitmq_prometheus': }

    # One more rabbit metric that isn't provided by the standard plugin
    file { '/usr/local/sbin/detect_rabbit_partition':
        owner  => 'root',
        group  => 'root',
        mode   => '0744',
        source => 'puppet:///modules/profile/openstack/base/rabbitmq/detect_rabbit_partition.py',
    }

    systemd::timer::job { 'rabbitmq_detect_partition':
        ensure      => present,
        description => 'Update prometheus metric about rabbit network partition',
        command     => '/usr/local/sbin/detect_rabbit_partition',
        user        => 'root',
        interval    => {'start' => 'OnCalendar', 'interval' => '*:0/2'}
    }

    firewall::service { 'rabbitmq-cloud-private':
        proto  => 'tcp',
        port   => [5671, 5672],
        srange => $cloud_private_supernet,
    }

    firewall::service { 'rabbitmq-internals':
        proto  => 'tcp',
        port   => [4369, 5671, 5672, 25672],
        srange => $rabbitmq_nodes + $rabbitmq_setup_nodes,
    }

    firewall::service { 'rabbitmq-cloud-vps-instances':
        proto    => 'tcp',
        port     => [5671, 5672],
        src_sets => ['CLOUD_NETWORKS'],
    }
}
