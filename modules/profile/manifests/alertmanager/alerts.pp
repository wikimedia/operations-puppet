# == Class: profile::alertmanager::alerts
#
# NOTE to be included only from one host, icinga will generate different alerts
# for all hosts that include this class.

class profile::alertmanager::alerts {
    monitoring::check_prometheus { 'alertmanager_config_invalid':
        description     => 'Alertmanager config is not valid',
        query           => 'alertmanager_config_last_reload_successful',
        prometheus_url  => 'https://thanos-query.discovery.wmnet',
        method          => 'le',
        warning         => 0,
        critical        => 0,
        dashboard_links => ['https://grafana.wikimedia.org/d/eea-9_sik/alertmanager'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Alertmanager#Alerts',
    }

    monitoring::check_prometheus { 'alertmanager_no_alerts_received':
        description     => 'Alertmanager has not been receiving alerts',
        query           => 'sum(rate(alertmanager_alerts_received_total[5m]))',
        prometheus_url  => 'https://thanos-query.discovery.wmnet',
        method          => 'le',
        warning         => 2,
        critical        => 1,
        retries         => 3,
        dashboard_links => ['https://grafana.wikimedia.org/d/eea-9_sik/alertmanager'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Alertmanager#Alerts',
    }

    monitoring::check_prometheus { 'alertmanager_config_out_of_sync':
        description     => 'Alertmanager cluster configuration is out of sync',
        query           => 'count(count_values("config_hash", alertmanager_config_hash))',
        prometheus_url  => 'https://thanos-query.discovery.wmnet',
        method          => 'ge',
        warning         => 2,
        critical        => 2,
        retries         => 45,
        dashboard_links => ['https://grafana.wikimedia.org/d/eea-9_sik/alertmanager'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Alertmanager#Alerts',
    }

    monitoring::check_prometheus { 'alertmanager_notifications_failed':
        description     => 'Alertmanager is failing to deliver notifications',
        query           => 'rate(alertmanager_notifications_failed_total[2m])',
        prometheus_url  => 'https://thanos-query.discovery.wmnet',
        method          => 'gt',
        warning         => 0.1,
        critical        => 0.2,
        retries         => 5,
        dashboard_links => ['https://grafana.wikimedia.org/d/eea-9_sik/alertmanager'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Alertmanager#Alerts',
    }

    monitoring::check_prometheus { 'irc_relay_not_connected':
        description     => 'Alertmanager IRC relay is not connected',
        query           => 'irc_connected',
        prometheus_url  => 'https://thanos-query.discovery.wmnet',
        method          => 'eq',
        warning         => 0,
        critical        => 0,
        retries         => 3,
        dashboard_links => ['https://grafana.wikimedia.org/d/eea-9_sik/alertmanager'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Alertmanager#Alerts',
    }

    monitoring::check_prometheus { 'irc_relay_not_joined_channels':
        description     => 'Alertmanager IRC relay has not joined channels',
        query           => 'count(count by (ircchannel) (irc_sent_msgs))',
        prometheus_url  => 'https://thanos-query.discovery.wmnet',
        method          => 'eq',
        warning         => 0,
        critical        => 0,
        retries         => 15,
        dashboard_links => ['https://grafana.wikimedia.org/d/eea-9_sik/alertmanager'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Alertmanager#Alerts',
    }

    monitoring::check_prometheus { 'alertmanager_prometheus_not_connected':
        description     => 'Prometheus is failing to connect to Alertmanager',
        query           => 'prometheus_notifications_alertmanagers_discovered',
        prometheus_url  => 'https://thanos-query.discovery.wmnet',
        method          => 'lt',
        warning         => 2,
        critical        => 1,
        retries         => 3,
        dashboard_links => ['https://grafana.wikimedia.org/d/eea-9_sik/alertmanager'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Alertmanager#Alerts',
    }
}
