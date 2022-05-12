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

      monitoring::check_prometheus { "mediawiki_workers_saturated_servers_ratio_${cluster}_${site}":
        description     => "Some MediaWiki servers are running out of idle PHP-FPM workers in ${cluster} at ${site}",
        query           => "count(sum by (instance) (phpfpm_statustext_processes{cluster=\"${cluster}\", state=\"active\"}) / sum by (instance) (phpfpm_statustext_processes{cluster=\"${cluster}\"}) > .6) / count(sum by (instance) (phpfpm_statustext_processes{cluster=\"${cluster}\"}))",
        prometheus_url  => "http://prometheus.svc.${site}.wmnet/ops",
        retries         => 3,
        method          => 'gt',
        warning         => 0.1,  # Ratio of # of servers with 60% workers busy to Total number of servers
        critical        => 0.3,
        notes_link      => 'https://bit.ly/wmf-fpmsat',
        dashboard_links => ['https://grafana.wikimedia.org/d/fRn9VEPMz/application-servers-use-dashboard-wip?orgId=1'],
        nagios_critical => false,
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
    query           => 'sum(log_mediawiki_level_channel_doc_count{channel="memcached", level="ERROR"})',
    prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
    retries         => 2,
    method          => 'gt',
    # Nominal error rate in production is <150/min
    warning         => 1000,
    critical        => 5000,
    notes_link      => 'https://wikitech.wikimedia.org/wiki/Memcached',
    dashboard_links => ["https://grafana.wikimedia.org/d/000000438/mediawiki-alerts?panelId=1&fullscreen&orgId=1&var-datasource=${::site} prometheus/ops"],
  }

  # Monitor MediaWiki fatals and exceptions per MediaWiki cluster.
  # From the logstash perspective, cluster is in the "servergroup" field
  ['appserver', 'api_appserver', 'jobrunner', 'parsoid'].each |String $cluster| {
    monitoring::check_prometheus { "mediawiki-error-rate-${cluster}":
      description     => "MediaWiki exceptions and fatals per minute for ${cluster}",
      prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
      retries         => 2,
      method          => 'gt',
      query           => "sum(log_mediawiki_servergroup_level_channel_doc_count{channel=~\"(fatal|exception)\", level=\"ERROR\", servergroup=\"${cluster}\"})",
      warning         => 50,
      critical        => 100,
      notes_link      => 'https://wikitech.wikimedia.org/wiki/Application_servers',
      dashboard_links => ["https://grafana.wikimedia.org/d/000000438/mediawiki-alerts?panelId=18&fullscreen&orgId=1&var-datasource=${::site} prometheus/ops"],
    }
  }
}
