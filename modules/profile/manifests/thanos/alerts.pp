# == Class: profile::thanos::alerts
#
# Install icinga alerts based on Prometheus metrics.
# NOTE to be included only from one host, icinga will generate different alerts
# for all hosts that include this class.
#
class profile::thanos::alerts (
    Array[String] $datacenters = lookup('datacenters'),
) {

    # Thanos store

    monitoring::check_prometheus { 'thanos_store_grpc_errors':
        description     => 'Thanos store has high gRPC errors',
        query           => @(QUERY/L)
        ( \
          sum by (job) (rate(grpc_server_handled_total{grpc_code=~"Unknown|ResourceExhausted|Internal|Unavailable|DataLoss|DeadlineExceeded", job=~"thanos-store.*"}[5m])) \
          / \
          sum by (job) (rate(grpc_server_started_total{job=~"thanos-store.*"}[5m])) \
        ) * 100
        | - QUERY
        ,
        prometheus_url  => 'https://thanos-query.discovery.wmnet',
        method          => 'ge',
        warning         => 2,
        critical        => 5,
        dashboard_links => ['https://grafana.wikimedia.org/d/e832e8f26403d95fac0ea1c59837588b/thanos-store'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Thanos#Alerts',
    }

    monitoring::check_prometheus { 'thanos_store_high_latency_gate':
        description     => 'Thanos store has high latency for series gate requests',
        query           => @(QUERY/L)
        histogram_quantile(0.9, sum by (job, le) (rate(thanos_bucket_store_series_gate_duration_seconds_bucket{job=~"thanos-store.*"}[5m]))) \
        and \
        sum by (job) (rate(thanos_bucket_store_series_gate_duration_seconds_count{job=~"thanos-store.*"}[5m])) > 0
        | - QUERY
        ,
        prometheus_url  => 'https://thanos-query.discovery.wmnet',
        method          => 'ge',
        warning         => 1,
        critical        => 2,
        dashboard_links => ['https://grafana.wikimedia.org/d/e832e8f26403d95fac0ea1c59837588b/thanos-store'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Thanos#Alerts',
    }

    monitoring::check_prometheus { 'thanos_store_bucket_failures':
        description     => 'Thanos store has high percentage of object storage failures',
        query           => @(QUERY/L)
        ( \
          sum by (job) (rate(thanos_objstore_bucket_operation_failures_total{job=~"thanos-compact.*"}[5m])) \
          / \
          sum by (job) (rate(thanos_objstore_bucket_operations_total{job=~"thanos-compact.*"}[5m])) \
        ) * 100
        | - QUERY
        ,
        prometheus_url  => 'https://thanos-query.discovery.wmnet',
        method          => 'ge',
        warning         => 2,
        critical        => 5,
        dashboard_links => ['https://grafana.wikimedia.org/d/e832e8f26403d95fac0ea1c59837588b/thanos-store'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Thanos#Alerts',
    }

    monitoring::check_prometheus { 'thanos_store_bucket_latency':
        description     => 'Thanos store has high latency to object storage',
        query           => @(QUERY/L)
        histogram_quantile(0.9, sum by (job, le) (rate(thanos_objstore_bucket_operation_duration_seconds_bucket{job=~"thanos-store.*"}[5m]))) \
        and \
        sum by (job) (rate(thanos_objstore_bucket_operation_duration_seconds_count{job=~"thanos-store.*"}[5m])) > 0
        | - QUERY
        ,
        prometheus_url  => 'https://thanos-query.discovery.wmnet',
        method          => 'ge',
        warning         => 1,
        critical        => 2,
        dashboard_links => ['https://grafana.wikimedia.org/d/e832e8f26403d95fac0ea1c59837588b/thanos-store'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Thanos#Alerts',
    }

    # Thanos sidecar

    monitoring::check_prometheus { 'thanos_sidecar_prometheus_down':
        description     => 'Thanos sidecar cannot connect to Prometheus',
        query           => 'thanos_sidecar_prometheus_up{job=~"thanos-sidecar.*"}',
        prometheus_url  => 'https://thanos-query.discovery.wmnet',
        method          => 'eq',
        warning         => 0,
        critical        => 0,
        dashboard_links => ['https://grafana.wikimedia.org/d/b19644bfbf0ec1e108027cce268d99f7/thanos-sidecar'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Thanos#Alerts',
    }

    monitoring::check_prometheus { 'thanos_sidecar_unhealthy':
        description     => 'Thanos sidecar is unhealthy',
        query           => 'count(time() - max(thanos_sidecar_last_heartbeat_success_time_seconds{job=~"thanos-sidecar.*"}) by (job) >= 300)',
        prometheus_url  => 'https://thanos-query.discovery.wmnet',
        method          => 'ge',
        warning         => 1,
        critical        => 1,
        dashboard_links => ['https://grafana.wikimedia.org/d/b19644bfbf0ec1e108027cce268d99f7/thanos-sidecar'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Thanos#Alerts',
    }

    monitoring::check_prometheus { 'thanos_sidecar_upload_failure':
        description     => 'Thanos sidecar is failing to upload blocks',
        query           => 'thanos_shipper_upload_failures_total',
        prometheus_url  => 'https://thanos-query.discovery.wmnet',
        method          => 'ge',
        warning         => 1,
        critical        => 1,
        dashboard_links => ['https://grafana.wikimedia.org/d/b19644bfbf0ec1e108027cce268d99f7/thanos-sidecar'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Thanos#Alerts',
    }

    # Catch a whole datacenter not configured to be uploading blocks. For full coverage of all
    # instances we'd need the <hostname>:<sidecar port> list and then check for absent() for all
    # of them. See also https://phabricator.wikimedia.org/T265632
    $datacenters.each |String $datacenter| {
        monitoring::check_prometheus { "thanos_sidecar_not_uploading_${datacenter}":
            description     => "Thanos sidecar is not configured to upload blocks in ${datacenter}",
            query           => "absent(thanos_shipper_uploads_total{site=\"${datacenter}\"})",
            prometheus_url  => 'https://thanos-query.discovery.wmnet',
            method          => 'eq',
            warning         => 1,
            critical        => 1,
            dashboard_links => ['https://grafana.wikimedia.org/d/b19644bfbf0ec1e108027cce268d99f7/thanos-sidecar'],
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Thanos#Alerts',
        }
    }

    # Thanos query

    monitoring::check_prometheus { 'thanos_query_http_error_query':
        description     => 'Thanos query has many failed HTTP instant queries requests',
        query           => @(QUERY/L)
        ( \
          sum(rate(http_requests_total{code=~"5..", job=~"thanos-query.*", handler="query"}[5m])) \
          / \
          sum(rate(http_requests_total{job=~"thanos-query.*", handler="query"}[5m])) \
        ) * 100
        | - QUERY
        ,
        prometheus_url  => 'https://thanos-query.discovery.wmnet',
        method          => 'ge',
        warning         => 3,
        critical        => 5,
        dashboard_links => ['https://grafana.wikimedia.org/d/af36c91291a603f1d9fbdabdd127ac4a/thanos-query'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Thanos#Alerts',
    }

    monitoring::check_prometheus { 'thanos_query_http_error_query_range':
        description     => 'Thanos query has many failed HTTP range queries requests',
        query           => @(QUERY/L)
        ( \
          sum(rate(http_requests_total{code=~"5..", job=~"thanos-query.*", handler="query_range"}[5m])) \
          / \
          sum(rate(http_requests_total{job=~"thanos-query.*", handler="query_range"}[5m])) \
        ) * 100
        | - QUERY
        ,
        prometheus_url  => 'https://thanos-query.discovery.wmnet',
        method          => 'ge',
        warning         => 3,
        critical        => 5,
        dashboard_links => ['https://grafana.wikimedia.org/d/af36c91291a603f1d9fbdabdd127ac4a/thanos-query'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Thanos#Alerts',
    }

    monitoring::check_prometheus { 'thanos_query_grpc_server_error':
        description     => 'Thanos query has high gRPC server errors',
        nan_ok          => true, # In normal circumstances Thanos query doesn't serve gRPC traffic
        query           => @(QUERY/L)
        ( \
          sum by (job) (rate(grpc_server_handled_total{grpc_code=~"Unknown|ResourceExhausted|Internal|Unavailable|DataLoss|DeadlineExceeded", job=~"thanos-query.*"}[5m])) \
          / \
          sum by (job) (rate(grpc_server_started_total{job=~"thanos-query.*"}[5m])) \
        ) * 100
        | - QUERY
        ,
        prometheus_url  => 'https://thanos-query.discovery.wmnet',
        method          => 'ge',
        warning         => 3,
        critical        => 5,
        dashboard_links => ['https://grafana.wikimedia.org/d/af36c91291a603f1d9fbdabdd127ac4a/thanos-query'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Thanos#Alerts',
    }

    monitoring::check_prometheus { 'thanos_query_grpc_client_error':
        description     => 'Thanos query has high gRPC client errors',
        query           => @(QUERY/L)
        ( \
          sum by (job) (rate(grpc_client_handled_total{grpc_code\\!="OK", job=~"thanos-query.*"}[5m])) \
          / \
          sum by (job) (rate(grpc_client_started_total{job=~"thanos-query.*"}[5m])) \
        ) * 100
        | - QUERY
        ,
        prometheus_url  => 'https://thanos-query.discovery.wmnet',
        method          => 'ge',
        warning         => 3,
        critical        => 5,
        dashboard_links => ['https://grafana.wikimedia.org/d/af36c91291a603f1d9fbdabdd127ac4a/thanos-query'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Thanos#Alerts',
    }

    monitoring::check_prometheus { 'thanos_query_high_latency_query':
        description     => 'Thanos query has high latency for instant queries',
        query           => @(QUERY/L)
        histogram_quantile(0.99, sum by (job, le) (rate(http_request_duration_seconds_bucket{job=~"thanos-query.*", handler="query"}[5m]))) \
        and \
        sum by (job) (rate(http_request_duration_seconds_bucket{job=~"thanos-query.*", handler="query"}[5m])) > 1
        | - QUERY
        ,
        prometheus_url  => 'https://thanos-query.discovery.wmnet',
        method          => 'ge',
        warning         => 35,
        critical        => 40,
        dashboard_links => ['https://grafana.wikimedia.org/d/af36c91291a603f1d9fbdabdd127ac4a/thanos-query'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Thanos#Alerts',
    }

    monitoring::check_prometheus { 'thanos_query_high_latency_range_query':
        description     => 'Thanos query has high latency for range queries',
        query           => @(QUERY/L)
        histogram_quantile(0.99, sum by (job, le) (rate(http_request_duration_seconds_bucket{job=~"thanos-query.*", handler="query_range"}[5m]))) \
        and \
        sum by (job) (rate(http_request_duration_seconds_bucket{job=~"thanos-query.*", handler="query_range"}[5m])) > 1
        | - QUERY
        ,
        prometheus_url  => 'https://thanos-query.discovery.wmnet',
        method          => 'ge',
        warning         => 80,
        critical        => 90,
        dashboard_links => ['https://grafana.wikimedia.org/d/af36c91291a603f1d9fbdabdd127ac4a/thanos-query'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Thanos#Alerts',
    }

    # Thanos query-frontend

    monitoring::check_prometheus { 'thanos_query-frontend_http_error_query':
        description     => 'Thanos query-frontend has many failed HTTP instant queries requests',
        query           => @(QUERY/L)
        ( \
          sum(rate(http_requests_total{code=~"5..", job=~"thanos-query.*", handler="query-frontend"}[5m])) \
          / \
          sum(rate(http_requests_total{job=~"thanos-query.*", handler="query-frontend"}[5m])) \
        ) * 100
        | - QUERY
        ,
        prometheus_url  => 'https://thanos-query.discovery.wmnet',
        method          => 'ge',
        warning         => 3,
        critical        => 5,
        dashboard_links => ['https://grafana.wikimedia.org/d/aa7Rx0oMk/thanos-query-frontend'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Thanos#Alerts',
    }

    monitoring::check_prometheus { 'thanos_query-frontend_high_latency_query':
        description     => 'Thanos query-frontend has high latency for queries',
        query           => @(QUERY/L)
        histogram_quantile(0.99, sum by (job, le) (rate(http_request_duration_seconds_bucket{job=~"thanos-query.*", handler="query-frontend"}[5m]))) \
        and \
        sum by (job) (rate(http_request_duration_seconds_bucket{job=~"thanos-query.*", handler="query-frontend"}[5m])) > 1
        | - QUERY
        ,
        prometheus_url  => 'https://thanos-query.discovery.wmnet',
        method          => 'ge',
        warning         => 35,
        critical        => 40,
        dashboard_links => ['https://grafana.wikimedia.org/d/aa7Rx0oMk/thanos-query-frontend'],
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Thanos#Alerts',
    }

    # Absent metrics

    ['compact', 'query', 'query-frontend', 'sidecar', 'store'].each |String $c| {
        monitoring::check_prometheus { "thanos_component_${c}_absent":
            description     => "Thanos ${c} has disappeared from Prometheus discovery",
            query           => "count(absent(up{job=~\"thanos-${c}\"} == 1))",
            prometheus_url  => 'https://thanos-query.discovery.wmnet',
            method          => 'ge',
            warning         => 1,
            critical        => 1,
            dashboard_links => ['https://grafana.wikimedia.org/d/0cb8830a6e957978796729870f560cda/thanos-overview'],
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Thanos#Alerts',
        }
    }
}
