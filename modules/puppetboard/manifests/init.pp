# SPDX-License-Identifier: Apache-2.0
# @summary configure puppetboard
# @see https://github.com/voxpupuli/puppetboard/#configuration
# @param ensure ensurable parameter
# @param puppetdb_host puppetdb host to connect to
# @param puppetdb_port puppetdb port to use
# @param puppetdb_ssl_verify If we shold verify TLS
# @param puppetdb_cert the puppet cert to use for client auth
# @param puppetdb_key the puppet key to use for client auth
# @param puppetdb_proto the protocol to use for connecting to puppetdb
# @param puppetdb_timeout the timeout to use for puppetdb connections
# @param page_title The page title
# @param default_environment The default puppet environment
# @param enable_catalog enable the catalog browser
# @param enable_query enable the query interface
# @param unresponsive_hours how long untill a host is considered unresponsive
# @param localise_timestamp If we should localize timestamps
# @param log_level the log level to use
# @param refresh_rate the refresh rate
# @param daily_reports_chart_enabled enable the daily report chart
# @param daily_reports_chart_days how many days for the daily report chart
# @param with_event_numbers  If set to True then Overview and Nodes list shows exact number of
#   changed resources in the last report. Otherwise shows only 'some' string if there are
#   resources with given status. Setting this to False gives performance benefits, especially in
#   big Puppet environment
# @param normal_table_count Default number of nodes to show when displaying reports and catalog nodes
# @param little_table_count  Default number of reports to show when when looking at a node.
# @param table_count_selector  Configure the dropdown to limit number of hosts to show per page.
# @param graph_type Specify the type of graph to display. Default is pie, other good option is donut.
#   Other choices can be found here: _C3JS_documentation`
# @param graph_facts_override A list of fact names to tell PuppetBoard to generate a pie-chart on the
#   fact page. With some fact values being unique per node, like ipaddress, uuid, and serial number,
#   as well as structured facts it was no longer feasible to generate a graph for everything.
# @param displayed_metrics_override
# @param inventory_facts_override  list of tuples that serve as the column header and the fact name to
#   search for to create the inventory page. If a fact is not found for a node then undef is printed.
# @param query_endpoints_override If enable_query is True, allow to fine tune the endpoints of PuppetDB
#   APIs that can be queried. It must be a list of strings of PuppetDB endpoints for which the query is
#   enabled. See the QUERY_ENDPOINTS constant in the puppetboard.app module for a list of the available
#   endpoints.
# @param overview_filter This allows to filter out nodes in the overview by passing queries to
#   the PuppetDB
# @param secret_key the secret key to use
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
        "${memo}${value[0]} = ${value[1].to_python}\n"
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
