# SPDX-License-Identifier: Apache-2.0
class profile::opensearch::monitoring::base_checks(
    Integer $shard_size_warning      = lookup('profile::opensearch::monitoring::shard_size_warning',      { 'default_value' => 110 }),
    Integer $shard_size_critical     = lookup('profile::opensearch::monitoring::shard_size_critical',     { 'default_value' => 140 }),
    String  $threshold               = lookup('profile::opensearch::monitoring::threshold',               { 'default_value' => '>=0.15' }),
    Integer $timeout                 = lookup('profile::opensearch::monitoring::timeout',                 { 'default_value' => 4 }),
    Boolean $enable_shard_size_check = lookup('profile::opensearch::monitoring::enable_shard_size_check', { 'default_value' => true }),
    Boolean $enable_unassigned_shard_check = lookup('profile::opensearch::monitoring::enable_unassigned_shard_check', { 'default_value' => true }),
) {
    require ::profile::opensearch::server

    class { 'icinga::elasticsearch::base_plugin': }

    $configured_ports = $::profile::opensearch::server::filtered_instances.reduce([]) |$ports, $instance_params| {
        $ports + [$instance_params[1]['http_port']]
    }

    $configured_ports.each |$port| {
        nrpe::monitor_service { "opensearch_shards_${port}":
          critical      => false,
          contact_group => 'admins,team-discovery',
          notes_url     => 'https://wikitech.wikimedia.org/wiki/Search#Administration',
          nrpe_command  => "/usr/lib/nagios/plugins/check_elasticsearch.py --ignore-status --url http://localhost:${port} --shards-inactive '${threshold}' --timeout ${timeout}",
          description   => "OpenSearch health check for shards on ${port}",
        }

        if $enable_unassigned_shard_check {
            nrpe::monitor_service { "opensearch_unassigned_shard_check_${port}":
              critical       => false,
              contact_group  => 'admins,team-discovery',
              notes_url      => 'https://wikitech.wikimedia.org/wiki/Search#Administration',
              nrpe_command   => "/usr/lib/nagios/plugins/check_elasticsearch_unassigned_shards.py --url http://localhost:${port} --timeout ${timeout}",
              description    => "OpenSearch unassigned shard check - ${port}",
              check_interval => 720, # 12h
              retry_interval => 120, # 2h
              retries        => 1,
            }
        }

        if $enable_shard_size_check {
            nrpe::monitor_service { "opensearch_shard_size_check_${port}":
              critical       => false,
              contact_group  => 'admins,team-discovery',
              notes_url      => 'https://wikitech.wikimedia.org/wiki/Search#If_it_has_been_indexed',
              nrpe_command   => "/usr/lib/nagios/plugins/check_elasticsearch_shard_size.py --url http://localhost:${port} --shard-size-warning ${shard_size_warning} --shard-size-critical ${shard_size_critical} --timeout ${timeout}",
              description    => "OpenSearch shard size check - ${port}",
              check_interval => 1440, # 24h
              retry_interval => 180, # 3h
            }
        }
    }
}
