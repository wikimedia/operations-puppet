# == Class: profile::prometheus::alerts
#
# Install icinga alerts based on Prometheus metrics.
# NOTE to be included only from one host, icinga will generate different alerts
# for all hosts that include this class.
#
class profile::prometheus::alerts {

    # Monitor Druid realtime ingestion event rate.
    # Experimental, only alerting the Analytics alias.
    monitoring::check_prometheus { 'druid_realtime_banner_activity':
        description     => 'Number of banner_activity realtime events received by Druid over a 30 minutes period',
        query           => 'scalar(sum(sum_over_time(druid_realtime_ingest_events_processed_count{cluster="druid_analytics", instance=~"druid.*:8000", datasource=~"banner_activity_minutely"}[30m])))',
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/analytics',
        method          => 'le',
        warning         => 10,
        critical        => 0,
        contact_group   => 'analytics',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/prometheus-druid?refresh=1m&panelId=41&fullscreen&orgId=1']
    }

    # Monitor Varnish HTTP availability as seen by looking at status codes
    monitoring::check_prometheus { 'varnish_text_http_availability':
        description     => 'HTTP availability for Varnish text (5m period)',
        query           => '1 - site_job:varnish_requests:avail5m{job="varnish-text"}',
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/global',
        method          => 'le',
        warning         => 99,
        critical        => 98,
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/frontend-traffic?panelId=3&fullscreen&orgId=1&from=now-3h&to=now&var-site=ulsfo&var-site=esams&var-site=eqiad&var-site=codfw&var-cache_type=text']
    }

    # Monitor Varnish HTTP availability as seen by looking at status codes
    monitoring::check_prometheus { 'varnish_upload_http_availability':
        description     => 'HTTP availability for Varnish upload (5m period)',
        query           => '1 - site_job:varnish_requests:avail5m{job="varnish-upload"}',
        prometheus_url  => 'http://prometheus.svc.eqiad.wmnet/global',
        method          => 'le',
        warning         => 99,
        critical        => 98,
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/frontend-traffic?panelId=3&fullscreen&orgId=1&from=now-3h&to=now&var-site=ulsfo&var-site=esams&var-site=eqiad&var-site=codfw&var-cache_type=upload']
    }
}
