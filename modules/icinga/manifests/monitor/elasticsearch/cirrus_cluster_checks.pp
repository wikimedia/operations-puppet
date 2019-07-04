# == Class icinga::monitor::elasticsearch::cirrus_cluster_checks
class icinga::monitor::elasticsearch::cirrus_cluster_checks{
    $ports = [9243, 9443, 9643]
    $sites = ['eqiad', 'codfw']
    $scheme = 'https'

    $sites.each |$site| {
        $host = "search.svc.${site}.wmnet"
        icinga::monitor::elasticsearch::base_checks { $host:
            host   => $host,
            scheme => $scheme,
            ports  => $ports,
        }

        icinga::monitor::elasticsearch::cirrus_checks { $host:
            host   => $host,
            scheme => $scheme,
            ports  => $ports,
        }

        # Alert on mjolnir daemons - T214494
        monitoring::check_prometheus { "mjolnir_bulk_update_failure_${site}":
            description     => "Mjolnir bulk update failure check - ${site}",
            dashboard_links => ['https://grafana.wikimedia.org/d/000000591/elasticsearch-mjolnir-bulk-updates?orgId=1&from=now-7d&to=now&panelId=1&fullscreen'],
            query           => 'sum(irate(mjolnir_bulk_action_total{result="failed"}[5m]))/sum(irate(mjolnir_bulk_action_total[5m]))',
            prometheus_url  => "http://prometheus.svc.${site}.wmnet/ops",
            nan_ok          => true,
            method          => 'gt',
            critical        => 0.01, # 1%
            warning         => 0.005, # 0.5%
            contact_group   => 'admins,team-discovery',
            notes_link      => 'https://phabricator.wikimedia.org/T214494',
        }

        # ensure kafka queue is empty at least once in a week
        # warning or critical here means critical
        # value for critical was bumped a bit to make check_prometheus_metrics.py work
        monitoring::check_prometheus { "cirrus_update_lag_${site}":
            description     => "Cirrus Update lag check - ${site}",
            dashboard_links => ['https://grafana.wikimedia.org/d/000000484/kafka-consumer-lag?orgId=1&from=now-7d&to=now'],
            query           => "scalar(sum(min_over_time(kafka_burrow_partition_lag{exported_cluster=~\"main-${site}\", topic=\"${site}.cirrussearch.page-index-update\", group=~\"cirrussearch_updates_${site}\"}[7d])))",
            prometheus_url  => "http://prometheus.svc.${site}.wmnet/ops",
            method          => 'gt',
            critical        => 2,
            warning         => 1,
            check_interval  => 1440, # 24h
            retries         => 1,
            contact_group   => 'admins,team-discovery',
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Search',
        }

        monitoring::graphite_threshold { "mediawiki_cirrus_update_rate_${site}":
            description     => "Mediawiki Cirrussearch update rate - ${site}",
            dashboard_links => ['https://grafana.wikimedia.org/d/JLK3I_siz/elasticsearch-indexing?panelId=44&fullscreen&orgId=1'],
            host            => $host,
            metric          => "movingAverage(transformNull(MediaWiki.CirrusSearch.${site}.updates.all.sent.rate),\"10minutes\")",
            warning         => 80,
            critical        => 50,
            under           => true,
            contact_group   => 'admins,team-discovery',
        }
    }
}
