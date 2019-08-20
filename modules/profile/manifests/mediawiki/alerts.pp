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
        description     => "High average GET latency for mediawiki requests on cluster ${cluster} in ${site}",
        # Filter out NaN values
        query           => "cluster_code_method_handler:mediawiki_http_requests_duration:avg2m{cluster=\"${cluster}\",method=\"GET\"} > 0",
        prometheus_url  => "http://prometheus.svc.${site}.wmnet/ops",
        method          => 'gt',
        warning         => 0.2, # seconds
        critical        => 0.3, # seconds
        dashboard_links => ["https://grafana.wikimedia.org/d/RIA1lzDZk/application-servers-red-dashboard?panelId=9&fullscreen&orgId=1&from=now-3h&to=now&var-datasource=${site} prometheus/ops&var-cluster=${cluster}&var-method=GET"],
      }

      monitoring::check_prometheus { "mediawiki_http_requests_${cluster}_${site}_post":
        description     => "High average POST latency for mediawiki requests on cluster ${cluster} in ${site}",
        # Filter out NaN values
        query           => "cluster_code_method_handler:mediawiki_http_requests_duration:avg2m{cluster=\"${cluster}\",method=\"POST\"} > 0",
        prometheus_url  => "http://prometheus.svc.${site}.wmnet/ops",
        method          => 'gt',
        warning         => 0.25, # seconds
        critical        => 0.3, # seconds
        dashboard_links => ["https://grafana.wikimedia.org/d/RIA1lzDZk/application-servers-red-dashboard?panelId=9&fullscreen&orgId=1&from=now-3h&to=now&var-datasource=${site} prometheus/ops&var-cluster=${cluster}&var-method=POST"],
      }

    }
  }
}
