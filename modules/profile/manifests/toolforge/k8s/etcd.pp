class profile::toolforge::k8s::etcd(
    Array[Stdlib::Fqdn] $peer_hosts    = lookup('profile::k8s::etcd_hosts',              {default_value => ['localhost']}),
    Array[Stdlib::Fqdn] $checker_hosts = lookup('profile::toolforge::checker_hosts',     {default_value => ['tools-checker-03.tools.eqiad.wmflabs']}),
    Array[Stdlib::Fqdn] $k8s_hosts     = lookup('profile::toolforge::k8s_masters_hosts', {default_value => ['localhost']}),
    String              $cluster_name  = lookup('profile::etcd::cluster_name',           {default_value => 'toolforge-k8s-etcd'}),
    Boolean             $bootstrap     = lookup('profile::etcd::cluster_bootstrap',      {default_value => false}),
    String              $discovery     = lookup('profile::etcd::discovery',              {default_value => 'no'}),
    Boolean             $client_certs  = lookup('profile::etcd::use_client_certs',       {default_value => false}),
    Boolean             $use_proxy     = lookup('profile::etcd::use_proxy',              {default_value => false}),
    Boolean             $do_backup     = lookup('profile::etcd::do_backup',              {default_value => false}),
    String              $allow_from    = lookup('profile::etcd::allow_from',             {default_value => 'localhost'}),
) {

    # TODO: this is an effort to provide some sane defaults for our environment
    # which could probably be improved
    if $allow_from == 'localhost' {
        $firewall_peers    = join(($peer_hosts), ' ')
        $firewall_checker  = join(($checker_hosts), ' ')
        $firewall_k8s      = join(($k8s_hosts), ' ')
        $actual_allow_from = "@resolve((${firewall_peers} ${firewall_checker} ${firewall_k8s}))"
    } else {
        $actual_allow_from = $allow_from
    }

    class { '::profile::etcd':
        cluster_name      => $cluster_name,
        cluster_bootstrap => $bootstrap,
        discovery         => $discovery,
        use_client_certs  => $client_certs,
        use_proxy         => $use_proxy,
        allow_from        => $actual_allow_from,
        do_backup         => $do_backup,
    }
    contain '::profile::etcd'

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
