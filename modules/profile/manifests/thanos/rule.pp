# SPDX-License-Identifier: Apache-2.0
# == Class: profile::thanos::rule
#
# Thanos rule is in charge of evaluating Prometheus recording and alerting rules.
#
# = Parameters
# [*rule_hosts*] A mapping from fqdn to labels to use. See thanos::rule for details.
# [*query_hosts*] A list of Thanos query hosts to allow access from.
# [*objstore_account*] The account to use to access object storage
# [*objstore_password*] The password to access object storage
# [*alertmanagers*] All alertmanagers to send alerts to


class profile::thanos::rule (
    Hash[Stdlib::Fqdn, Hash] $thanos_rule_hosts = lookup('profile::thanos::rule_hosts'),
    Array $query_hosts = lookup('profile::thanos::frontends'),
    Hash[String, String] $objstore_account = lookup('profile::thanos::objstore_account'),
    String $objstore_password = lookup('profile::thanos::objstore_password'),
    Array[Stdlib::Host] $alertmanagers = lookup('alertmanagers'),
    String $public_domain = lookup('public_domain'),
) {
    $http_port = 17902
    $grpc_port = 17901

    # XXX expose web interface like /bucket/ ?
    class { 'thanos::rule':
        alertmanagers     => $alertmanagers,
        # /etc/thanos-rule paths are reserved for puppet-deployed files, whereas /srv paths
        # will receive automatically-deployed alerts.
        rule_files        => ['/etc/thanos-rule/rules/*.yaml',
                              '/etc/thanos-rule/alerts/*.yaml',
                              '/srv/alerts-thanos/*.yaml'],
        rule_hosts        => $thanos_rule_hosts,
        use_objstore      => true,
        objstore_account  => $objstore_account,
        objstore_password => $objstore_password,
        http_port         => $http_port,
        grpc_port         => $grpc_port,
        query_url         => "https://thanos.${public_domain}",
    }

    if $::fqdn in $thanos_rule_hosts {
        class { 'thanos::rule::prometheus': }
    }

    # Allow access from query hosts
    $query_hosts_ferm = join($query_hosts, ' ')
    ferm::service { 'thanos_rule_query':
        proto  => 'tcp',
        port   => $grpc_port,
        srange => "(@resolve((${query_hosts_ferm})) @resolve((${query_hosts_ferm}), AAAA))",
    }

    # Deploy Thanos recording rules
    thanos::recording_rule { 'recording_rules.yaml':
        source   => 'puppet:///modules/profile/thanos/recording_rules.yaml',
    }
}
