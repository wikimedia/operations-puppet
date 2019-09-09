# == Define: profile::cache::kafka::varnishkafka_delivery_alert
#
# Define to ease the creation of all per-dc Varnishkafka Prometheus
# check for Delivery error failures.
#
define profile::cache::kafka::varnishkafka_delivery_alert(
    String $cache_segment,
    String $instance,

) {
    monitoring::check_prometheus { "varnishkafka-${instance}-${cache_segment}-eqiad-kafka_drerr":
        description     => "cache_${cache_segment}: Varnishkafka ${instance} Delivery Errors per second (eqiad)",
        dashboard_links => ["https://grafana.wikimedia.org/d/000000253/varnishkafka?panelId=20&fullscreen&orgId=1&var-datasource=eqiad prometheus/ops&var-source=${instance}&var-cp_cluster=cache_${cache_segment}&var-instance=All"],
        query           => "scalar(sum(irate(varnishkafka_delivery_errors_total{cluster=\"cache_${cache_segment}\", source=\"${instance}\"}[5m])))",
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/ops',
        warning         => 1,
        critical        => 5,
        contact_group   => 'analytics',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Varnishkafka',
    }
    monitoring::check_prometheus { "varnishkafka-${instance}-${cache_segment}-codfw-kafka_drerr":
        description     => "cache_${cache_segment}: Varnishkafka ${instance} Delivery Errors per second (codfw)",
        dashboard_links => ["https://grafana.wikimedia.org/d/000000253/varnishkafka?panelId=20&fullscreen&orgId=1&var-datasource=codfw prometheus/ops&prometheus/ops&var-source=${instance}&var-cp_cluster=cache_${cache_segment}&var-instance=All"],
        query           => "scalar(sum(irate(varnishkafka_delivery_errors_total{cluster=\"cache_${cache_segment}\", source=\"${instance}\"}[5m])))",
        prometheus_url  => 'http://prometheus.svc.codfw.wmnet/ops',
        warning         => 1,
        critical        => 5,
        contact_group   => 'analytics',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Varnishkafka',
    }
    monitoring::check_prometheus { "varnishkafka-${instance}-${cache_segment}-esams-kafka_drerr":
        description     => "cache_${cache_segment}: Varnishkafka ${instance} Delivery Errors per second (esams)",
        dashboard_links => ["https://grafana.wikimedia.org/d/000000253/varnishkafka?panelId=20&fullscreen&orgId=1&var-datasource=esams prometheus/ops&var-source=${instance}&var-cp_cluster=cache_${cache_segment}&var-instance=All"],
        query           => "scalar(sum(irate(varnishkafka_delivery_errors_total{cluster=\"cache_${cache_segment}\", source=\"${instance}\"}[5m])))",
        prometheus_url  => 'http://prometheus.svc.esams.wmnet/ops',
        warning         => 1,
        critical        => 5,
        contact_group   => 'analytics',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Varnishkafka',
    }
    monitoring::check_prometheus { "varnishkafka-${instance}-${cache_segment}-ulsfo-kafka_drerr":
        description     => "cache_${cache_segment}: Varnishkafka ${instance} Delivery Errors per second (ulsfo)",
        dashboard_links => ["https://grafana.wikimedia.org/d/000000253/varnishkafka?panelId=20&fullscreen&orgId=1&var-datasource=ulsfo prometheus/ops&var-source=${instance}&var-cp_cluster=cache_${cache_segment}&var-instance=All"],
        query           => "scalar(sum(irate(varnishkafka_delivery_errors_total{cluster=\"cache_${cache_segment}\", source=\"${instance}\"}[5m])))",
        prometheus_url  => 'http://prometheus.svc.ulsfo.wmnet/ops',
        warning         => 1,
        critical        => 5,
        contact_group   => 'analytics',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Varnishkafka',
    }
    monitoring::check_prometheus { "varnishkafka-${instance}-${cache_segment}-eqsin-kafka_drerr":
        description     => "cache_${cache_segment}: Varnishkafka ${instance} Delivery Errors per second (eqsin)",
        dashboard_links => ["https://grafana.wikimedia.org/d/000000253/varnishkafka?panelId=20&fullscreen&orgId=1&var-datasource=eqsin prometheus/ops&var-source=${instance}&var-cp_cluster=cache_${cache_segment}&var-instance=All"],
        query           => "scalar(sum(irate(varnishkafka_delivery_errors_total{cluster=\"cache_${cache_segment}\", source=\"${instance}\"}[5m])))",
        prometheus_url  => 'http://prometheus.svc.eqsin.wmnet/ops',
        warning         => 1,
        critical        => 5,
        contact_group   => 'analytics',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Varnishkafka',
    }
}
