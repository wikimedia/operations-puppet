# == Class: profile::thanos::rule
#
# Thanos rule is in charge of evaluating Prometheus recording and alerting rules.
#
# = Parameters
# [*prometheus_nodes*] The list of Prometheus hosts available in this site.
# [*rule_hosts*] A mapping from fqdn to labels to use. See thanos::rule for details.
# [*query_hosts*] A list of Thanos query hosts to allow access from.
# [*objstore_account*] The account to use to access object storage
# [*objstore_password*] The password to access object storage
# [*alertmanagers*] All alertmanagers to send alerts to


class profile::thanos::rule (
    Array $prometheus_nodes = lookup('prometheus_nodes'),
    Hash[Stdlib::Fqdn, Hash] $thanos_rule_hosts = lookup('profile::thanos::rule_hosts'),
    Array $query_hosts = lookup('profile::thanos::frontends'),
    Hash[String, String] $objstore_account = lookup('profile::thanos::objstore_account'),
    String $objstore_password = lookup('profile::thanos::objstore_password'),
    Array[Stdlib::Host] $alertmanagers = lookup('alertmanagers'),
) {
    $http_port = 17902
    $grpc_port = 17901

    # XXX expose web interface like /bucket/ ?
    class { 'thanos::rule':
        alertmanagers     => $alertmanagers,
        rule_files        => ['/etc/thanos-rule/rules/*.yaml', '/etc/thanos-rule/alerts/*.yaml'],
        rule_hosts        => $thanos_rule_hosts,
        objstore_account  => $objstore_account,
        objstore_password => $objstore_password,
        http_port         => $http_port,
        grpc_port         => $grpc_port,
    }

    if $::fqdn in $thanos_rule_hosts {
        class { 'thanos::rule::prometheus': }
    }

    # Allow access only to rule to scrape metrics
    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')
    ferm::service { 'thanos_rule':
        proto  => 'tcp',
        port   => $http_port,
        srange => "(@resolve((${prometheus_nodes_ferm})) @resolve((${prometheus_nodes_ferm}), AAAA))",
    }

    # Allow access from query hosts
    $query_hosts_ferm = join($query_hosts, ' ')
    ferm::service { 'thanos_rule_query':
        proto  => 'tcp',
        port   => $grpc_port,
        srange => "(@resolve((${query_hosts_ferm})) @resolve((${query_hosts_ferm}), AAAA))",
    }
}
