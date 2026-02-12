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
# [*object_store_cutoff_days*] Block retention time (in days, as an Integer) on local disk.

class profile::thanos::rule::main (
    Hash[Stdlib::Fqdn, Hash] $thanos_rule_hosts = lookup('profile::thanos::rule_hosts'),
    Array $query_hosts = lookup('profile::thanos::frontends'),
    Hash[String, String] $objstore_account = lookup('profile::thanos::objstore_account'),
    String $objstore_password = lookup('profile::thanos::objstore_password'),
    Array[Stdlib::Host] $alertmanagers = lookup('alertmanagers'),
    String $public_domain = lookup('public_domain'),
    Optional[Integer] $object_store_cutoff_days = lookup('profile::thanos::object_store_cutoff_days', { 'default_value' => undef }),
) {
    $http_port = 17902
    $grpc_port = 17901

    thanos::rule { 'main':
        alertmanagers     => $alertmanagers,
        # rule_files will be automatically merged with the default /etc/thanos-rule@ paths for puppet-deployed
        # files, whereas /srv paths will receive rules/alerts deployed by other means.
        rule_files        => [
            '/srv/alerts-thanos/*.yaml',
            '/etc/pyrra/output-rules/*.yaml',
            '/srv/slothslos@main/*.yaml',
        ],
        rule_hosts        => $thanos_rule_hosts,
        use_objstore      => true,
        objstore_account  => $objstore_account,
        objstore_password => $objstore_password,
        http_port         => $http_port,
        grpc_port         => $grpc_port,
        query_url         => "https://thanos.${public_domain}",
        # Thanos Rule accepts input in the form of an interval (e.g., '15d' represents 15 days).
        # The cutoff parameter is expressed in days as an Integer, and here we adjust the format to the correct string.
        retention_time    => sprintf('%dd', $object_store_cutoff_days + 1),
        tracing_enabled   => true,
        query_hosts       => $query_hosts,
    }

    profile::thanos::query::store_config { 'main':
        hosts     => $thanos_rule_hosts,
        grpc_port => $grpc_port,
    }

    if $facts['networking']['fqdn'] in $thanos_rule_hosts {
        # placeholder class to be able to fetch thanos-rule hosts
        # as Prometheus job targets
        class { 'thanos::rule::prometheus': }

        prometheus::pint::source { 'thanos-query-frontend':
            port       => 16902,
            url_path   => '',
            all_alerts => true,
        }

        # promql/rate needs to read Prometheus config via
        # /api/v1/status/config which Thanos doesn't expose or proxy
        prometheus::pint::config { 'disable-checks':
            content => @(CONFIG)
                checks {
                    disabled = ["promql/rate"]
                }
                |- CONFIG
        }
    } else {
        class { 'prometheus::pint':
            ensure => absent,
        }
    }

    # Deploy Thanos recording rules
    thanos::recording_rule { 'recording_rules.yaml':
        source   => 'puppet:///modules/profile/thanos/recording_rules.yaml',
    }

    # Deploy Thanos metamonitoring rules
    thanos::recording_rule { 'metamonitoring_rules.yaml':
        source   => 'puppet:///modules/profile/thanos/metamonitoring_rules.yaml',
    }
}
