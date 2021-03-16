# == Class: profile::logstash::alerts
#
# NOTE to be included only from one host, icinga will generate different alerts
# for all hosts that include this class.

class profile::logstash::alerts {
    monitoring::check_prometheus { 'logstash_no_logs_indexed':
        description     => 'Logstash logs are not being indexed by Elasticsearch #o11y',
        query           => 'sum(irate(elasticsearch_indices_indexing_index_total{cluster="logstash"}[5m]))',
        prometheus_url  => 'https://thanos-query.discovery.wmnet',
        method          => 'le',
        warning         => 100,
        critical        => 10,
        dashboard_links => ['https://grafana.wikimedia.org/d/000000561/logstash'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Logstash#No_logs_indexed',
    }

    # Alert on unusual day-over-day logstash ingestion rate change - T202307
    monitoring::check_prometheus { 'logstash_ingestion_spike':
        description     => 'Logstash rate of ingestion percent change compared to yesterday #o11y',
        # Divide rate of input now vs yesterday, multiplied by 100
        query           => '100 * (sum (rate(logstash_node_plugin_events_out_total{plugin_id=~"input/.*"}[5m])) / sum (rate(logstash_node_plugin_events_out_total{plugin_id=~"input/.*"}[5m] offset 1d)))',
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/ops',
        warning         => 150,
        critical        => 210,
        method          => 'ge',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/logstash?orgId=1&panelId=2&fullscreen'],
        # Check every 120 minutes, once in breach check every 10 minutes up to 5 times
        check_interval  => 120,
        retry_interval  => 10,
        retries         => 5,
        notes_link      => 'https://phabricator.wikimedia.org/T202307',
    }

    # Logstash Elasticsearch indexing failures - T236343 T240667
    monitoring::check_prometheus { 'logstash_ingestion_errors':
        description     => 'Logstash Elasticsearch indexing errors #o11y',
        dashboard_links => ['https://logstash.wikimedia.org/goto/3283cc1372b7df18f26128163125cf45', 'https://grafana.wikimedia.org/dashboard/db/logstash'],
        query           => 'sum(log_dead_letters_hits)',
        warning         => 60,  # 1 event/sec
        critical        => 480, # 60 seconds * 8 events/sec
        method          => 'ge',
        retries         => 2,
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Logstash#Indexing_errors',
    }

    ['eqiad', 'codfw'].each |String $site| {
        monitoring::check_prometheus { "kafka logging-${site} consumer lag":
            description     => "Too many messages in kafka logging-${site} #o11y",
            query           => "kafka_burrow_partition_lag{exported_cluster=\"logging-${site}\"}",
            prometheus_url  => 'https://thanos-query.discovery.wmnet',
            warning         => 1000,
            critical        => 1500,
            retries         => 10,
            method          => 'ge',
            dashboard_links => ["https://grafana.wikimedia.org/d/000000484/kafka-consumer-lag?from=now-3h&to=now&orgId=1&var-datasource=thanos&var-cluster=logging-${site}&var-topic=All&var-consumer_group=All"],
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Logstash#Kafka_consumer_lag',
        }
    }
}
