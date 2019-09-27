# == Class: profile::mediawiki::alerts
#
# Install icinga alerts based on Prometheus metrics.
# NOTE to be included only from one host, icinga will generate different alerts
# for all hosts that include this class.
#
class profile::mediawiki::alerts {
  ['eqiad', 'codfw'].each |String $site| {
    ['appserver', 'api_appserver'].each |String $cluster| {
      monitoring::check_prometheus { "mediawiki_http_requests_${cluster}_${site}_get":
        description     => "High average GET latency for mw requests on ${cluster} in ${site}",
        # Filter out NaN values
        query           => "cluster_code_method_handler:mediawiki_http_requests_duration:avg2m{cluster=\"${cluster}\",method=\"GET\",code=~\"2..\"} > 0",
        prometheus_url  => "http://prometheus.svc.${site}.wmnet/ops",
        retries         => 2,
        method          => 'gt',
        warning         => 0.35, # seconds
        critical        => 0.4, # seconds
        dashboard_links => ["https://grafana.wikimedia.org/d/RIA1lzDZk/application-servers-red-dashboard?panelId=9&fullscreen&orgId=1&from=now-3h&to=now&var-datasource=${site} prometheus/ops&var-cluster=${cluster}&var-method=GET"],
      }

      monitoring::check_prometheus { "mediawiki_http_requests_${cluster}_${site}_post":
        description     => "High average POST latency for mw requests on ${cluster} in ${site}",
        # Filter out NaN values
        query           => "cluster_code_method_handler:mediawiki_http_requests_duration:avg2m{cluster=\"${cluster}\",method=\"POST\",code=~\"2..\"} > 0",
        prometheus_url  => "http://prometheus.svc.${site}.wmnet/ops",
        retries         => 2,
        method          => 'gt',
        warning         => 1.4, # seconds
        critical        => 2.0, # seconds
        dashboard_links => ["https://grafana.wikimedia.org/d/RIA1lzDZk/application-servers-red-dashboard?panelId=9&fullscreen&orgId=1&from=now-3h&to=now&var-datasource=${site} prometheus/ops&var-cluster=${cluster}&var-method=POST"],
      }

    }
  }

  ### Logstash-based MediaWiki alerts: these don't need to iterate over sites.
  ### Logstash in codfw/eqiad site reads logs from all other sites' kafka,
  ### making the metrics we calculate from it effectively global. Thus icinga
  ### in each site only needs to check its local prometheus instance.

  # Monitor memcached error rate from MediaWiki. This is commonly a sign of
  # a failing nutcracker instance that can be tracked down via
  # https://logstash.wikimedia.org/#/dashboard/elasticsearch/memcached
  monitoring::check_prometheus { 'mediawiki-memcached-threshold':
    description     => 'MediaWiki memcached error rate',
    query           => 'sum(irate(logstash_mediawiki_events_total{channel="memcached", level="ERROR"}[5m])) * 60',
    prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
    retries         => 2,
    method          => 'gt',
    # Nominal error rate in production is <150/min
    warning         => 1000,
    critical        => 5000,
    notes_link      => 'https://wikitech.wikimedia.org/wiki/Memcached',
    dashboard_links => ["https://grafana.wikimedia.org/d/000000438/mediawiki-alerts?panelId=1&fullscreen&orgId=1&var-datasource=${::site} prometheus/ops"],
  }

  # Monitor MediaWiki fatals and exceptions.
  monitoring::check_prometheus { 'mediawiki-error-rate':
    description     => 'MediaWiki exceptions and fatals per minute',
    prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
    retries         => 2,
    method          => 'gt',
    query           => 'sum(irate(logstash_mediawiki_events_total{channel=~"(fatal|exception)",level="ERROR"}[10m])) without (channel, instance) * 60',
    warning         => 25,
    critical        => 50,
    notes_link      => 'https://wikitech.wikimedia.org/wiki/Application_servers',
    dashboard_links => ["https://grafana.wikimedia.org/d/000000438/mediawiki-alerts?panelId=2&fullscreen&orgId=1&var-datasource=${::site} prometheus/ops"],
  }
}
