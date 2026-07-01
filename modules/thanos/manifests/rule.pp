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
# [*query_url*] The publicly-reachable Thanos query URL to attach to alerts
# [*http_port*] The port to use for HTTP
# [*grpc_port*] The port to use for gRPC
# [*retention_time*] Block retention time on local disk
# [*tracing_enabled*] Self explanatory

define thanos::rule (
    Hash[Stdlib::Fqdn, Hash] $rule_hosts,
    Boolean $use_objstore,
    Array[Stdlib::Host] $alertmanagers,
    Array[String] $rule_files,
    Stdlib::HTTPSUrl $query_url,
    Wmflib::Ensure $ensure = present,
    Stdlib::Port::Unprivileged $query_port = 16902, #thanos query-frontend
    Stdlib::Port::Unprivileged $http_port = 17902,
    Stdlib::Port::Unprivileged $grpc_port = 17901,
    String $retention_time = '2d',
    Boolean $tracing_enabled = false,
    Array[String] $add_labels = [],
    Firewall::Hosts $query_hosts = [],
    Optional[Hash[String, String]] $objstore_account,
    Optional[String] $objstore_password,
) {
    ensure_packages(['thanos'])

    if $use_objstore and ($objstore_account == undef or $objstore_password == undef) {
        fail('thanos::rule: objstore_account and objstore_password are required when use_objstore is true')
    }

    $http_address = "0.0.0.0:${http_port}"
    $grpc_address = "0.0.0.0:${grpc_port}"
    $service_name = "thanos-rule@${title}"
    $service_reload = "thanos-rule-reload@${title}"
    $data_dir = "/srv/${service_name}"
    $conf_dir = "/etc/${service_name}"
    $objstore_config_file = "${conf_dir}/objstore.yaml"
    $tracing_config_file = "${conf_dir}/tracing-config.yml"
    $am_config_file = "${conf_dir}/alertmanagers.yaml"
    $am_config = { 'alertmanagers' => [
        { 'static_configs' => $alertmanagers.map |$a| { "${a}:9093" } }
    ]}
    $replica = $facts['networking']['fqdn'] in $rule_hosts ? {
        true  => $rule_hosts[$facts['networking']['fqdn']]['replica'],
        false => 'unset'
    }
    $relabel_config_file = "${conf_dir}/relabel.yaml"
    $relabel_config = [
      # Add 'source' label
      { 'target_label' => 'source', 'replacement' => 'thanos', 'action' => 'replace' },
    ]
    $default_rule_files = [ "${conf_dir}/rules/*.yaml",
                            "${conf_dir}/alerts/*.yaml" ]
    $merged_rule_files = unique($default_rule_files + $rule_files)

    file { $data_dir:
        ensure => directory,
        mode   => '0750',
        owner  => 'thanos',
        group  => 'thanos',
    }

    file { $conf_dir:
        ensure => directory,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    file { "${conf_dir}/rules":
        ensure => directory,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    if $use_objstore and $ensure == 'present' {
        file { $objstore_config_file:
            ensure    => file,
            mode      => '0440',
            owner     => 'thanos',
            group     => 'root',
            show_diff => false,
            content   => template('thanos/objstore.yaml.erb'),
        }
    } else {
        file { $objstore_config_file:
            ensure => absent,
        }
    }

    thanos::tracing { $tracing_config_file:
        service_name => $service_name,
        sampler_type => 'parentbasedalwayssample',
        notify       => Service[$service_name],
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
        if $facts['networking']['fqdn'] in $rule_hosts {
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
        content        => systemd_template('thanos-rule@'),
        service_params => {
            enable     => $service_enable,
            hasrestart => true,
        },
    }

    systemd::service { $service_reload:
        ensure         => $service_ensure,
        restart        => false,
        content        => systemd_template('thanos-rule-reload@'),
        service_params => {
            enable     => $service_enable,
            ensure     => 'stopped',
            hasrestart => true,
        },
    }

    unless $query_hosts.empty() {
        # Allow grpc access from query hosts
        firewall::service { "thanos_rule_query_${title}":
            proto  => 'tcp',
            port   => $grpc_port,
            srange => $query_hosts,
        }

        # Allow http access to reverse-proxy /rule
        firewall::service { "thanos_rule_web_${title}":
            proto  => 'tcp',
            port   => $http_port,
            srange => $query_hosts,
        }
    }
}
