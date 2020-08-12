class profile::alertmanager (
    Stdlib::Host        $active_host = lookup('profile::icinga::active_host'),
    Array[Stdlib::Host] $partners    = lookup('profile::icinga::partners'),
    String              $irc_channel = lookup('profile::alertmanager::irc::channel'),
    Optional[String]    $victorops_api_key = lookup('profile::alertmanager::victorops_api_key'),
    Array $prometheus_all_nodes = lookup('prometheus_all_nodes'),
) {
    class { '::alertmanager':
        irc_channel       => $irc_channel,
        active_host       => $active_host,
        partners          => $partners,
        victorops_api_key => $victorops_api_key,
    }

    # All Prometheus servers need access to Alertmanager to send alerts
    $prometheus_nodes_ferm = join($prometheus_all_nodes, ' ')
    ferm::service { 'alertmanager-prometheus':
        proto  => 'tcp',
        port   => '9093',
        srange => "(@resolve((${prometheus_nodes_ferm})))",
    }

    $hosts = join($partners + $active_host, ' ')
    ferm::service{ 'alertmanager-cluster':
        proto  => 'tcp',
        port   => '9094',
        srange => "@resolve((${hosts}))",
    }
}
