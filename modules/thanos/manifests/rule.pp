# SPDX-License-Identifier: Apache-2.0
# == Class: thanos::rule
#
# The thanos rule component runs Prometheus queries and is in charge of evaluating the following
# rules:
# * recording rules, and upload results to object storage
# * alerting rules, and send matching alerts to alertmanager

# Each site is meant to run one rule process for redudancy purposes, though more per site can be run
# at the same time (with distinct 'replica' labels). Each thanos rule will query its local thanos
# query on 'localhost'.

# The rule component also exposes StoreAPI and is discovered and queried by thanos query: this way
# recording rules are also available for querying.

# There are risks involved in evaluating rules when sites could be unavailable, read more at
# https://thanos.io/tip/components/rule.md/#risk

# = Parameters
# [*rule_hosts*] A mapping from fqdn to labels to use (currently 'replica' only).
#     This variable is expected to be something like { 'host1.domain' => { "replica" => "a" }, ... }
# [*objstore_account*] The account to use to access object storage
# [*objstore_password*] The password to access object storage
# [*alertmanagers*] All alertmanagers to send alerts to
# [*rule_files*] A list of globs to files to evaluate as rules
# [*http_port*] The port to use for HTTP
# [*grpc_port*] The port to use for gRPC

class thanos::rule (
    Hash[Stdlib::Fqdn, Hash] $rule_hosts,
    Hash[String, String] $objstore_account,
    String $objstore_password,
    Array[Stdlib::Host] $alertmanagers,
    Array[String] $rule_files,
    Wmflib::Ensure $ensure = present,
    Stdlib::Port::Unprivileged $query_port = 10902,
    Stdlib::Port::Unprivileged $http_port = 17902,
    Stdlib::Port::Unprivileged $grpc_port = 17901,
) {
    ensure_packages(['thanos'])

    $http_address = "0.0.0.0:${http_port}"
    $grpc_address = "0.0.0.0:${grpc_port}"
    $service_name = 'thanos-rule'
    $data_dir = '/srv/thanos-rule'
    $objstore_config_file = '/etc/thanos-rule/objstore.yaml'
    $am_config_file = '/etc/thanos-rule/alertmanagers.yaml'
    $am_config = { 'alertmanagers' => [
        { 'static_configs' => $alertmanagers.map |$a| { "${a}:9093" } }
    ]}
    $replica = $::fqdn in $rule_hosts ? {
        true  => $rule_hosts[$::fqdn]['replica'],
        false => 'unset'
    }
    $relabel_config_file = '/etc/thanos-rule/relabel.yaml'
    $relabel_config = [
      # Add 'source' label
      { 'target_label' => 'source', 'replacement' => 'thanos', 'action' => 'replace' },
    ]

    file { $data_dir:
        ensure => directory,
        mode   => '0750',
        owner  => 'thanos',
        group  => 'thanos',
    }

    file { '/etc/thanos-rule':
        ensure => directory,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    file { '/etc/thanos-rule/rules':
        ensure => directory,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    file { $objstore_config_file:
        ensure    => $ensure,
        mode      => '0440',
        owner     => 'thanos',
        group     => 'root',
        show_diff => false,
        content   => template('thanos/objstore.yaml.erb'),
    }

    file { $am_config_file:
        ensure  => $ensure,
        mode    => '0444',
        owner   => 'thanos',
        group   => 'root',
        content => to_yaml($am_config),
    }

    file { $relabel_config_file:
        ensure  => $ensure,
        mode    => '0444',
        owner   => 'thanos',
        group   => 'root',
        content => to_yaml($relabel_config),
    }

    if $ensure != present {
        $service_ensure = $ensure
    } else { # handle fqdn-based service running/stopped status
        if $::fqdn in $rule_hosts {
            $service_ensure = 'present'
            $service_enable = true
        } else {
            $service_ensure = 'absent'
            $service_enable = false
        }
    }

    systemd::service { $service_name:
        ensure         => $service_ensure,
        restart        => true,
        override       => true,
        content        => systemd_template('thanos-rule'),
        service_params => {
            enable     => $service_enable,
            hasrestart => true,
        },
    }
}
