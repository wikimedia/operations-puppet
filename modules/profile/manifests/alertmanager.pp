# SPDX-License-Identifier: Apache-2.0
class profile::alertmanager (
    Stdlib::Host        $active_host = lookup('profile::alertmanager::active_host'),
    Array[Stdlib::Host] $partners    = lookup('profile::alertmanager::partners'),
    Array[Stdlib::Host] $grafana_hosts = lookup('profile::alertmanager::grafana_hosts', { 'default_value' => [] }),
    Array[Stdlib::Host] $thanos_query_hosts = lookup('profile::alertmanager::thanos_query_hosts', { 'default_value' => [] }),
    String              $irc_channel = lookup('profile::alertmanager::irc::channel'),
    Optional[String]    $victorops_api_key = lookup('profile::alertmanager::victorops_api_key'),
    Array $prometheus_all_nodes = lookup('prometheus_all_nodes'),
    # lint:ignore:wmf_styleguide - T260574
    String $vhost  = lookup('profile::alertmanager::web::vhost', {'default_value' => "alerts.${facts['domain']}"}),
    # lint:endignore
    Optional[Boolean]   $sink_notifications = lookup('profile::alertmanager::sink_notifications', { 'default_value' => false }),
) {
    class { '::alertmanager':
        irc_channel        => $irc_channel,
        active_host        => $active_host,
        partners           => $partners,
        victorops_api_key  => $victorops_api_key,
        vhost              => $vhost,
        sink_notifications => $sink_notifications,
    }

    # All Prometheus servers need access to Alertmanager to send alerts
    firewall::service { 'alertmanager-prometheus':
        proto  => 'tcp',
        port   => 9093,
        srange => $prometheus_all_nodes + $grafana_hosts + $thanos_query_hosts,
    }

    firewall::service{ 'alertmanager-cluster':
        proto  => 'tcp',
        port   => 9094,
        srange => $partners + $active_host,
    }
}
