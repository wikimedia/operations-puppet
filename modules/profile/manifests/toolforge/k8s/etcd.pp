class profile::toolforge::k8s::etcd(
    Array[Stdlib::Fqdn] $peer_hosts    = lookup('profile::toolforge::k8s::etcd_hosts',   {default_value => ['localhost']}),
    Array[Stdlib::Fqdn] $checker_hosts = lookup('profile::toolforge::checker_hosts',     {default_value => ['tools-checker-03.tools.eqiad.wmflabs']}),
    Array[Stdlib::Fqdn] $k8s_hosts     = lookup('profile::toolforge::k8s_masters_hosts', {default_value => ['localhost']}),
    Boolean             $bootstrap     = lookup('profile::etcd::cluster_bootstrap',      {default_value => false}),
) {
    if $bootstrap {
        $cluster_state = 'new'
    } else {
        $cluster_state = 'existing'
    }

    # for $peers_list we need a string like this:
    # node1=https://node1.eqiad.wmflabs:2380,node2=https://node2.eqiad.wmflabs:2380,node3=https://node3.eqiad.wmflabs:2380
    $protocol    = 'https://'
    $port        = ':2380'
    $peers_list_array = map($peer_hosts) |$element| {
        $value = "${element}=${protocol}${element}${port}"
    }
    $peers_list = join(($peers_list_array), ',')

    class { '::etcd::v3':
        member_name   => $::fqdn,
        cluster_state => $cluster_state,
        peers_list    => $peers_list,
        client_cert   => "/var/lib/puppet/ssl/certs/${::fqdn}.pem",
        client_key    => "/var/lib/puppet/ssl/private_keys/${::fqdn}.pem",
        trusted_ca    => '/var/lib/puppet/ssl/certs/ca.pem',
        peer_cert     => "/var/lib/puppet/ssl/certs/${::fqdn}.pem",
        peer_key      => "/var/lib/puppet/ssl/private_keys/${::fqdn}.pem",
    }

    # add the etcd user to the puppet group so it can read puppet certs
    user { 'etcd':
        ensure => 'present',
        groups => 'puppet',
    }

    $checker_hosts_string = join(($checker_hosts), ' ')
    $k8s_hosts_string     = join(($k8s_hosts), ' ')
    $firewall_clients     = "@resolve((${checker_hosts_string} ${k8s_hosts_string}))"
    ferm::service { 'etcd_clients':
        proto  => 'tcp',
        port   => 2379,
        srange => $firewall_clients,
    }

    $peer_hosts_string = join(($peer_hosts), ' ')
    $firewall_peers    = "@resolve((${peer_hosts_string}))"
    ferm::service { 'etcd_peers':
        proto  => 'tcp',
        port   => 2380,
        srange => $firewall_peers,
    }

    # from role::toollabs::etcd::expose_metrics
    $exposed_port = '9051'

    nginx::site { 'expose_etcd_metrics':
        content => template('profile/toolforge/k8s/etcd/etcd_expose_metrics.nginx.erb'),
    }

    ferm::service { 'etcd-metrics':
        proto => 'tcp',
        port  => $exposed_port,
    }
}
