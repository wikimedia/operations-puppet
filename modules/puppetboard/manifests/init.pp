# SPDX-License-Identifier: Apache-2.0
class puppetboard (
    # puppetdb settings
    Wmflib::Ensure                      $ensure                      = 'present',
    Stdlib::Host                        $puppetdb_host               = 'localhost',
    Stdlib::Port                        $puppetdb_port               = 8080,
    Puppetboard::SSL_verify             $puppetdb_ssl_verify         = true,
    Optional[Stdlib::Unixpath]          $puppetdb_cert               = undef,
    Optional[Stdlib::Unixpath]          $puppetdb_key                = undef,
    Optional[Enum['http', 'https']]     $puppetdb_proto              = undef,
    Integer[1,120]                      $puppetdb_timeout            = 20,
    # Application settings
    String                              $page_title                  = 'Puppetboard',
    String                              $default_environment         = 'production',
    Boolean                             $enable_catalog              = false,
    Boolean                             $enable_query                = true,
    Integer[1,24]                       $unresponsive_hours          = 2,
    Boolean                             $localise_timestamp          = true,
    Puppetboard::LogLevel               $log_level                   = 'info',
    Integer[1,360]                      $refresh_rate                = 30,
    Boolean                             $daily_reports_chart_enabled = true,
    Integer[1,31]                       $daily_reports_chart_days    = 8,
    Boolean                             $with_event_numbers          = true,
    Integer[10,500]                     $normal_table_count          = 100,
    Integer[1,50]                       $little_table_count          = 10,
    Array[Integer]                      $table_count_selector        = [10, 20, 50, 100, 500],
    String                              $graph_type                  = 'pie',
    Array[String]                       $graph_facts_override        = [],
    Array[String]                       $displayed_metrics_override  = [],
    Hash[String, String]                $inventory_facts_override    = {},
    Array[Puppetboard::Query_endpoints] $query_endpoints_override    = [],
    Optional[String]                    $overview_filter             = undef,
    Optional[Sensitive[String[24]]]     $secret_key                  = undef,

) {
    ensure_packages('puppetboard')
    $displayed_metrics_defaults = ['resources.total', 'events.failure', 'events.success',
                                  'resources.skipped', 'events.noop']
    $graph_facts_defaults = ['architecture', 'clientversion', 'domain', 'lsbcodename',
                            'lsbdistcodename', 'lsbdistid', 'lsbdistrelease', 'lsbmajdistrelease',
                            'netmask', 'osfamily', 'puppetversion', 'processorcount']
    $query_endpoints_default = ['pql', 'nodes', 'resources', 'facts', 'factsets', 'fact-paths',
                                'reports', 'events', 'edges', 'environments']
    $inventory_facts_defaults = {
        'Hostname'       => 'fqdn',
        'IP Address'     => 'ipaddress',
        'OS'             => 'lsbdistdescription',
        'Architecture'   => 'hardwaremodel',
        'Kernel Version' => 'kernelrelease',
        'Puppet Version' => 'puppetversion',
    }
    $displayed_metrics = $displayed_metrics_override.empty ? {
        false   => $displayed_metrics_override,
        default => $displayed_metrics_defaults,
    }
    $graph_facts = $graph_facts_override.empty ? {
        false   => $graph_facts_override,
        default => $graph_facts_defaults,
    }
    $enabled_query_endpoints = $query_endpoints_override.empty ? {
        false   => $query_endpoints_override,
        default => $query_endpoints_default,
    }
    $inventory_facts = Tuple($inventory_facts_override.empty ? {
        false   => $inventory_facts_override,
        default => $inventory_facts_defaults,
    })
    $_secret_key = $secret_key ? {
        undef   => 'os.urandom(24)',
        default => "'${secret_key.unwrap}'",
    }

    $config = {
        'PUPPETDB_HOST'               => $puppetdb_host,
        'PUPPETDB_PORT'               => $puppetdb_port,
        'PUPPETDB_PROTO'              => $puppetdb_proto,
        'PUPPETDB_SSL_VERIFY'         => $puppetdb_ssl_verify,
        'PUPPETDB_KEY'                => $puppetdb_key,
        'PUPPETDB_CERT'               => $puppetdb_cert,
        'PUPPETDB_TIMEOUT'            => $puppetdb_timeout,
        'DEFAULT_ENVIRONMENT'         => $default_environment,
        'UNRESPONSIVE_HOURS'          => $unresponsive_hours,
        'ENABLE_QUERY'                => $enable_query,
        'ENABLED_QUERY_ENDPOINTS'     => $enabled_query_endpoints,
        'LOCALISE_TIMESTAMP'          => $localise_timestamp,
        'LOGLEVEL'                    => $log_level,
        'NORMAL_TABLE_COUNT'          => $normal_table_count,
        'LITTLE_TABLE_COUNT'          => $little_table_count,
        'TABLE_COUNT_SELECTOR'        => $table_count_selector,
        'DISPLAYED_METRICS'           => $displayed_metrics,
        'ENABLE_CATALOG'              => $enable_catalog,
        'OVERVIEW_FILTER'             => $overview_filter,
        'PAGE_TITLE'                  => $page_title,
        'GRAPH_TYPE'                  => $graph_type,
        'GRAPH_FACTS'                 => $graph_facts,
        'INVENTORY_FACTS'             => $inventory_facts,
        'REFRESH_RATE'                => $refresh_rate,
        'DAILY_REPORTS_CHART_ENABLED' => $daily_reports_chart_enabled,
        'DAILY_REPORTS_CHART_DAYS'    => $daily_reports_chart_days,
        'WITH_EVENT_NUMBERS'          => $with_event_numbers,
    }.reduce('') |$memo, $value| {
        "${memo}${value[0]} = ${value[1].wmflib::to_python}\n"
    }
    $config_content = @("CONFIG")
    import os
    SECRET_KEY = ${_secret_key}
    ${config}
    | CONFIG
    $config_file = '/etc/puppetboard/settings.py'
    file {$config_file:
        ensure  => stdlib::ensure($ensure, 'file'),
        content => $config_content,
    }

}
