# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::kubeadm::etcd (
    Array[Stdlib::Fqdn] $peer_hosts     = lookup('profile::wmcs::kubeadm::etcd_nodes',   {default_value => ['localhost']}),
    Array[Stdlib::Fqdn] $control_nodes  = lookup('profile::wmcs::kubeadm::control_nodes',{default_value => ['localhost']}),
    Boolean             $bootstrap      = lookup('profile::etcd::cluster_bootstrap',     {default_value => false}),
    Integer             $latency_ms     = lookup('profile::wmcs::kubeadm::etcd_latency_ms', {default_value => 10}),
    Integer             $snapshot_count = lookup('profile::wmcs::kubeadm::etcd_snapshot_count', {default_value => 10000}),
) {
    if $bootstrap {
        $cluster_state = 'new'
    } else {
        $cluster_state = 'existing'
    }

    # for $peers_list we need a string like this:
    # node1=https://node1.project.eqiad.wmflabs:2380,node2=https://node2.project.eqiad.wmflabs:2380,node3=https://node3.project.eqiad.wmflabs:2380
    $protocol    = 'https://'
    $port        = ':2380'
    $peers_list_array = map($peer_hosts) |$element| {
        $value = "${element}=${protocol}${element}${port}"
    }
    $peers_list = join(($peers_list_array), ',')

    # the certificate trick
    $etcd_cert_pub    = "/etc/etcd/ssl/${facts['networking']['fqdn']}.pem"
    $etcd_cert_priv   = "/etc/etcd/ssl/${facts['networking']['fqdn']}.priv"
    $etcd_cert_ca     = '/etc/etcd/ssl/ca.pem'
    $puppet_cert_pub  = $facts['puppet_config']['hostcert']
    $puppet_cert_priv = $facts['puppet_config']['hostprivkey']
    $puppet_cert_ca   = profile::base::certificates::get_trusted_ca_path()

    file { ['/etc/etcd/', '/etc/etcd/ssl/']:
        ensure => directory,
    }

    file { $etcd_cert_pub:
        ensure  => present,
        source  => "file://${puppet_cert_pub}",
        owner   => 'etcd',
        group   => 'etcd',
        notify  => Service['etcd'],
        require => Package['etcd-server'],
    }

    file { $etcd_cert_priv:
        ensure    => present,
        source    => "file://${puppet_cert_priv}",
        owner     => 'etcd',
        group     => 'etcd',
        mode      => '0640',
        show_diff => false,
        notify    => Service['etcd'],
        require   => Package['etcd-server'],
    }

    file { $etcd_cert_ca:
        ensure  => present,
        source  => "file://${puppet_cert_ca}",
        owner   => 'etcd',
        group   => 'etcd',
        notify  => Service['etcd'],
        require => Package['etcd-server'],
    }

    class { '::etcd::v3':
        member_name      => $::fqdn,
        cluster_state    => $cluster_state,
        max_latency_ms   => $latency_ms,
        snapshot_count   => $snapshot_count,
        peers_list       => $peers_list,
        client_cert      => $etcd_cert_pub,
        client_key       => $etcd_cert_priv,
        trusted_ca       => $etcd_cert_ca,
        peer_cert        => $etcd_cert_pub,
        peer_key         => $etcd_cert_priv,
        use_client_certs => true,
    }

    # restart the etcd service if a cert file changes
    File[$etcd_cert_pub]  ~> Service[etcd]
    File[$etcd_cert_priv] ~> Service[etcd]
    File[$etcd_cert_ca]   ~> Service[etcd]

    $control_hosts_string = join(($control_nodes), ' ')
    $peer_hosts_string    = join(($peer_hosts), ' ')
    $firewall_clients     = "@resolve((${control_hosts_string} ${peer_hosts_string}))"
    ferm::service { 'etcd_clients':
        proto  => 'tcp',
        port   => 2379,
        srange => $firewall_clients,
    }

    $firewall_peers    = "@resolve((${peer_hosts_string}))"
    ferm::service { 'etcd_peers':
        proto  => 'tcp',
        port   => 2380,
        srange => $firewall_peers,
    }

    #
    # this is for metrics collections. The etcd server requires client certs
    # to fetch metrics. We have a nginx proxy to hide the TLS details from the
    # prometheus client.
    #
    $exposed_port = '9051'
    nginx::site { 'expose_etcd_metrics':
        content => template('profile/toolforge/k8s/etcd/etcd_expose_metrics.nginx.erb'),
    }

    ferm::service { 'etcd-metrics':
        proto => 'tcp',
        port  => $exposed_port,
    }

    # restart the nginx service if a cert file changes
    File[$etcd_cert_pub]  ~> Service[nginx]
    File[$etcd_cert_priv] ~> Service[nginx]
    File[$etcd_cert_ca]   ~> Service[nginx]
}
