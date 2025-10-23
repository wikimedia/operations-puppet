# SPDX-License-Identifier: Apache-2.0
# == Class: profile::thanos::query::store_config
#
# Deploys configuration for an individual thanos query store backend
#
# [*hosts*] Target hosts
# [*sd_files_path*] Path to thanos query store.sd files
# [*grpc_port*] Instance grpc port number

define profile::thanos::query::store_config (
    Hash[String, Hash] $hosts,
    Integer $grpc_port,
    String $sd_files_path = '/etc/thanos-query/stores',
) {

    $rule_targets = [ { 'targets' => $hosts.keys.map |$h| { "${h}:${grpc_port}" } } ]
    file { "${sd_files_path}/thanos-rule@${title}.yml":
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => to_yaml($rule_targets),
    }

}
