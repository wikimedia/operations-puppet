# SPDX-License-Identifier: Apache-2.0
# Uses the prometheus module and generates the specific configuration
# needed for WMF production
#
class profile::prometheus::ops (
    Array[Stdlib::Host] $prometheus_nodes                     = lookup('prometheus_nodes'),
    String $storage_retention                                 = lookup('prometheus::server::storage_retention', { 'default_value' => '3024h' }), # 4.5 months
    Optional[Stdlib::Datasize] $storage_retention_size        = lookup('prometheus::server::storage_retention_size', {default_value => undef}),
    Integer $max_chunks_to_persist                            = lookup('prometheus::server::max_chunks_to_persist', { 'default_value' => 524288 }),
    Integer $memory_chunks                                    = lookup('prometheus::server::memory_chunks', { 'default_value' => 1048576 }),
    Stdlib::Unixpath $targets_path                            = lookup('prometheus::server::target_path', { 'default_value' => '/srv/prometheus/ops/targets' }),
    Array[Stdlib::Host] $bastion_hosts                        = lookup('bastion_hosts', { 'default_value' => [] }),
    Stdlib::Host $netmon_server                               = lookup('netmon_server'),
    String $replica_label                                     = lookup('prometheus::replica_label', { 'default_value' => 'unset' }),
    Boolean $enable_thanos_upload                             = lookup('profile::prometheus::enable_thanos_upload', { 'default_value' => false }),
    Optional[String] $thanos_min_time                         = lookup('profile::prometheus::thanos::min_time', { 'default_value' => undef }),
    Array $alertmanagers                                      = lookup('alertmanagers', {'default_value' => []}),
    Boolean $disable_compaction                               = lookup('profile::prometheus::thanos::disable_compaction', { 'default_value' => false }),
    Array[Stdlib::HTTPUrl] $blackbox_pingthing_http_check_urls = lookup('profile::prometheus::ops::blackbox_pingthing_http_check_urls', { 'default_value' => [] }),
    Array[Stdlib::HTTPUrl] $blackbox_pingthing_proxied_urls    = lookup('profile::prometheus::ops::blackbox_pingthing_proxied_urls', { 'default_value' => [] }),
    Optional[Stdlib::HTTPUrl] $http_proxy                     = lookup('http_proxy', {default_value => undef}),
    Wmflib::Infra::Devices $infra_devices                     = lookup('infra_devices'),
    Array                  $alerting_relabel_configs_extra    = lookup('profile::prometheus::ops::alerting_relabel_configs_extra'),
    Array[Stdlib::Host] $ganeti_clusters                      = lookup('profile::prometheus::ganeti::clusters', { 'default_value' => []}),
    Prometheus::Blackbox::SmokeHosts $blackbox_smoke_hosts    = lookup('blackbox_smoke_hosts'),
){
    include ::passwords::gerrit
    $gerrit_client_token = $passwords::gerrit::prometheus_bearer_token

    include passwords::wikidough::dnsdist
    $wikidough_password = $passwords::wikidough::dnsdist::password

    $port = 9900

    $config_extra = {
        # All metrics will get an additional 'site' label when queried by
        # external systems (e.g. via federation)
        'external_labels' => {
            'site'       => $::site,
            'replica'    => $replica_label,
            'prometheus' => 'ops',
        },
    }

    class{ '::prometheus::swagger_exporter': }
    class{ '::prometheus::blackbox_exporter':
        http_proxy => $http_proxy,
    }

    # Blackbox jobs share the same relabel config
    $blackbox_relabel_configs = [
      { 'source_labels' => ['__address__'],
        'target_label'  => '__param_target',
      },
      { 'source_labels' => ['__param_target'],
        'target_label'  => 'instance',
      },
      { 'target_label' => '__address__',
        'replacement'  => '127.0.0.1:9115',
      },
    ]

    $blackbox_jobs = [
      {
        'job_name'        => 'blackbox/icmp',
        'metrics_path'    => '/probe',
        'params'          => {
          'module' => [ 'icmp' ],
        },
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/blackbox_icmp_*.yaml" ] }
        ],
        'relabel_configs' => $blackbox_relabel_configs,
      },
      {
        'job_name'        => 'blackbox/ssh',
        'metrics_path'    => '/probe',
        'params'          => {
          'module' => [ 'ssh_banner' ],
        },
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/blackbox_ssh_*.yaml" ] }
        ],
        'relabel_configs' => $blackbox_relabel_configs,
      },
      {
        'job_name'        => 'blackbox/tcp',
        'metrics_path'    => '/probe',
        'params'          => {
          'module' => [ 'tcp_connect' ],
        },
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/blackbox_tcp_*.yaml" ] }
        ],
        'relabel_configs' => $blackbox_relabel_configs,
      },
      {
        'job_name'        => 'blackbox/http',
        'metrics_path'    => '/probe',
        'params'          => {
          'module' => [ 'http_connect' ],
        },
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/blackbox_http_*.yaml" ] }
        ],
        'relabel_configs' => $blackbox_relabel_configs,
      },
      {
        'job_name'        => 'blackbox/https',
        'metrics_path'    => '/probe',
        'params'          => {
          'module' => [ 'https_connect' ],
        },
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/blackbox_https_*.yaml" ] }
        ],
        'relabel_configs' => $blackbox_relabel_configs,
      },
      {
        'job_name'        => 'blackbox/pingthing',
        'metrics_path'    => '/probe',
        'params'          => {
          'module' => [ 'http_connect_23xx' ],
        },
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/blackbox_pingthing_http_check_urls.yaml" ] }
        ],
        'relabel_configs' => $blackbox_relabel_configs,
      },
      {
        'job_name'        => 'blackbox/pingthing_proxied',
        'metrics_path'    => '/probe',
        'params'          => {
          'module' => [ 'http_connect_23xx_proxied' ],
        },
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/blackbox_pingthing_proxied_urls.yaml" ] }
        ],
        'relabel_configs' => $blackbox_relabel_configs,
      },
    ]

    # Local blackbox_exporter needs configuration (modules) generated from service::catalog
    class { '::prometheus::blackbox::modules::service_catalog':
        services_config => wmflib::service::fetch(),
    }

    # Relabel configuration to support for targets in the following forms to
    # keep 'instance' label readable:
    # - bare target (i.e. no @) -> copy unmodified to 'instance'
    # - target in the form of foo@bar -> use foo as 'instance' and 'bar' as target

    # This allows targets in the form of e.g.:
    # - target: 'foo:443@https://foo.discovery.wmnet:443/path'
    # will become:
    # - instance: 'foo:443' (for usage as metric label)
    # - target: 'https://foo.discovery.wmnet:443/path' (full url for blackbox to probe)

    # Note that all regex here are implicitly anchored (^<regex>$)
    $probes_relabel_configs = [
      { 'source_labels' => ['__address__'],
        'regex'         => '([^@]+)',
        'target_label'  => 'instance',
      },
      { 'source_labels' => ['__address__'],
        'regex'         => '([^@]+)',
        'target_label'  => '__param_target',
      },
      { 'source_labels' => ['__address__'],
        'regex'         => '(.+)@(.+)',
        'target_label'  => 'instance',
        'replacement'   => '${1}', # lint:ignore:single_quote_string_with_variables
      },
      { 'source_labels' => ['__address__'],
        'regex'         => '(.+)@(.+)',
        'target_label'  => '__param_target',
        'replacement'   => '${2}', # lint:ignore:single_quote_string_with_variables
      },
      { 'source_labels' => ['module'],
        'target_label'  => '__param_module',
      },
      { 'target_label' => '__address__',
        'replacement'  => '127.0.0.1:9115',
      },
    ]

    # Jobs for network probes. As of Feb 2022 service::catalog is probed,
    # though the same jobs can be reused for any network endpoint.
    # Targets in these jobs are expected to contain the
    # following labels:
    # - address => the endpoint address
    # - family  => ip4/ip6
    # - module  => the blackbox-exporter module to use

    # The scrape interval is 15s since we'd like to have higher
    # resolution probe status (e.g. to see recovery faster)
    $probes_jobs = [
      {
        'job_name'        => 'probes/service',
        'metrics_path'    => '/probe',
        'scrape_interval' => '15s',
        # blackbox-exporter will use the lower value between this and
        # the module configured timeout. We want the latter, therefore
        # set a high timeout here (but no longer than scrape_interval)
        'scrape_timeout'  => '15s',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/probes-service_*.yaml" ] }
        ],
        'relabel_configs' => $probes_relabel_configs,
      },
      {
        'job_name'        => 'probes/custom',
        'metrics_path'    => '/probe',
        'scrape_interval' => '15s',
        # blackbox-exporter will use the lower value between this and
        # the module configured timeout. We want the latter, therefore
        # set a high timeout here (but no longer than scrape_interval)
        'scrape_timeout'  => '15s',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/probes-custom_*.yaml" ] }
        ],
        'relabel_configs' => $probes_relabel_configs,
      },
      # Probes for the management network (ssh). Scrape interval is higher since mgmt is lower
      # priority and mgmt SSH interfaces have been historically finicky
      {
        'job_name'        => 'probes/mgmt',
        'metrics_path'    => '/probe',
        'scrape_interval' => '240s',
        # blackbox-exporter will use the lower value between this and
        # the module configured timeout. We want the latter, therefore
        # set a high timeout here (but no longer than scrape_interval)
        'scrape_timeout'  => '15s',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/probes-mgmt_*.yaml" ] }
        ],
        'relabel_configs' => $probes_relabel_configs,
      },

      # Smokeping replacement jobs, implemented with Blackbox exporter
      {
        'job_name'        => 'smoke/icmp',
        'metrics_path'    => '/probe',
        'scrape_interval' => '15s',
        'scrape_timeout'  => '3s',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/smoke-icmp_*.yaml" ] }
        ],
        'relabel_configs' => $probes_relabel_configs,
      },
      {
        'job_name'        => 'smoke/dns',
        'metrics_path'    => '/probe',
        'scrape_interval' => '15s',
        'scrape_timeout'  => '3s',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/smoke-dns_*.yaml" ] }
        ],
        'relabel_configs' => $probes_relabel_configs,
      },
      {
        'job_name'        => 'smoke/mgmt',
        'metrics_path'    => '/probe',
        'scrape_interval' => '45s',
        'scrape_timeout'  => '3s',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/smoke-mgmt_*.yaml" ] }
        ],
        'relabel_configs' => $probes_relabel_configs,
      },
    ]

    $probe_services = wmflib::service::fetch().filter |$name, $config| {
        ('probes' in $config and
          $::site in $config['sites'] and
          $config['state'] == 'production')
    }

    # Populate target files for probes jobs defined above
    if !empty($probe_services) {
      prometheus::targets::service_catalog { 'public':
        services_config => $probe_services,
        targets_file    => "${targets_path}/probes-service_catalog_public.yaml",
        networks        => slice_network_constants('production', { 'sphere' => 'public', 'site' => $::site }),
      }

      prometheus::targets::service_catalog { 'private':
        services_config => $probe_services,
        targets_file    => "${targets_path}/probes-service_catalog_private.yaml",
        networks        => slice_network_constants('production', { 'sphere' => 'private', 'site' => $::site }),
      }
    }

    # Write targets for Prometheus to ping core routers, targeting all sites.
    # The 'ops' Prometheus instance is deployed to all sites, therefore giving full mesh ping
    $core_routers = $infra_devices.filter |$device, $config| {
      $config['role'] == 'cr'
    }

    netops::prometheus::icmp { 'core-routers':
      targets      => $core_routers,
      targets_file => "${targets_path}/smoke-icmp_core-routers.yaml",
    }

    # Target L3 switches from within the same site. L2 switches have addresses on the
    # management network only, therefore not interesting for production monitoring.
    $access_switches = $infra_devices.filter |$device, $config| {
      $config['role'] == 'l3sw' and $config['site'] == $::site
    }

    netops::prometheus::icmp { 'access-switches':
      targets      => $access_switches,
      targets_file => "${targets_path}/smoke-icmp_access-switches.yaml",
    }

    # Ping Fundraising firewalls from within the same site
    $fr_firewalls = $infra_devices.filter |$device, $config| {
      $config['role'] == 'pfw' and $config['site'] == $::site
    }

    netops::prometheus::icmp { 'fr-firewalls':
      targets      => $fr_firewalls,
      targets_file => "${targets_path}/smoke-icmp_fr-firewalls.yaml",
    }

    netops::prometheus::dns { 'wikipedia':
      targets      => ['ns0.wikimedia.org', 'ns1.wikimedia.org', 'ns2.wikimedia.org'],
      modules      => ['dns_wikipedia_a', 'dns_wikipedia_cname'],
      targets_file => "${targets_path}/smoke-dns_wikipedia.yaml",
    }

    # Add hosts from hiera to be pinged, from within their site
    $site_smoke_hosts = $blackbox_smoke_hosts.filter |$host, $config| {
      $config['site'] == $::site
    }

    netops::prometheus::hosts { 'hiera':
      targets      => $site_smoke_hosts,
      targets_file => "${targets_path}/smoke-icmp_hosts-hiera.yaml",
    }

    include profile::netbox::data

    $site_mgmt_hosts = $profile::netbox::data::mgmt.filter |$host, $config| {
      $config['site'] == $::site
    }

    netops::prometheus::mgmt { 'site':
      targets      => $site_mgmt_hosts,
      targets_file => "${targets_path}/smoke-mgmt_site.yaml",
    }

    prometheus::targets::mgmt { 'site':
      targets      => $site_mgmt_hosts,
      targets_file => "${targets_path}/probes-mgmt_site.yaml",
    }

    # Checks for custom probes, defined in puppet
    prometheus::blackbox::import_checks { 'ops':
      prometheus_instance => 'ops',
      site                => $::site,
    }

    # Export local textfile metrics.
    # Restricted to localhost (i.e. Prometheus hosts) and used to export
    # arbitrarily-labeled metrics (e.g. metrics with 'instance' labels)
    class{ '::prometheus::mini_textfile_exporter': }
    $mini_textfile_jobs = [
      {
        'job_name'        => 'mini-textfile',
        'honor_labels'    => true,
        'static_configs' => [
          { 'targets' => [ 'localhost:9716' ] },
        ],
      },
    ]

    # Export service status from service::catalog info
    class { '::prometheus::service_catalog_metrics':
        services_config => wmflib::service::fetch(),
        outfile         => '/var/lib/prometheus/mini-textfile.d/service_catalog_metrics.prom',
    }


    # Special setup for Gerrit, internal hostnames don't serve data, thus limit polling gerrit
    # from eqiad and codfw only (as opposed to all sites).
    # See also https://phabricator.wikimedia.org/T184086
    if !($::site in ['eqiad', 'codfw']) {
      $gerrit_jobs = []
    } else {
      $gerrit_jobs = [
        # JVM metrics exposed by JavaMelody
        {
            'job_name'          => 'gerrit',
            'bearer_token_file' => '/srv/prometheus/ops/gerrit.token',
            'metrics_path'      => '/r/monitoring',
            'params'            => { 'format' => ['prometheus'] },
            'scheme'            => 'https',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/gerrit.yaml" ] }
            ],
            'tls_config'        => {
                'server_name'   => 'gerrit.wikimedia.org',
            },
        },
        # Gerrit internal metrics
        #
        # https://gerrit.wikimedia.org/r/Documentation/metrics.html
        # Exposed by the metrics-reporter-prometheus plugin at a different URL,
        # the token is shared with the above job.
        {
            'job_name'          => 'gerrit-metrics',
            'bearer_token_file' => '/srv/prometheus/ops/gerrit.token',
            'metrics_path'      => '/r/plugins/metrics-reporter-prometheus/metrics',
            'params'            => { 'format' => ['prometheus'] },
            'scheme'            => 'https',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/gerrit.yaml" ] }
            ],
            'tls_config'        => {
                'server_name'   => 'gerrit.wikimedia.org',
            },
        },
      ]
    }

    # Add one job for each of mysql 'group' (i.e. their broad function)
    # Each job will look for new files matching the glob and load the job
    # configuration automatically.
    # REMEMBER to change mysqld_exporter_config.py if you change these
    $mysql_jobs = [
      {
        'job_name'        => 'mysql-core',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/mysql-core_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'mysql-dbstore',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/mysql-dbstore_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'mysql-labs',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/mysql-labsdb_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'mysql-misc',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/mysql-misc_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'mysql-parsercache',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/mysql-parsercache_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'mysql-test',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/mysql-test_*.yaml"] },
        ]
      },
    ]

    # Leave only backend hostname (no VCL UUID) from "varnish_backend" metrics
    # to avoid metric churn on VCL regeneration. See also T150479.
    $varnish_be_uuid_relabel = {
      'source_labels' => ['__name__', 'id'],
      'regex'         => 'varnish_backend_.+;root:[-a-f0-9]+\.(.*)',
      'target_label'  => 'id',
    }

    # one job per varnish cache 'role'
    $varnish_jobs = [
      {
        'job_name'        => 'varnish-text',
        'file_sd_configs' => [
          { 'files' => ["${targets_path}/varnish-text_*.yaml"] },
        ],
        'metric_relabel_configs' => [$varnish_be_uuid_relabel],
      },
      {
        'job_name'        => 'varnish-upload',
        'file_sd_configs' => [
          { 'files' => ["${targets_path}/varnish-upload_*.yaml"] },
        ],
        'metric_relabel_configs' => [$varnish_be_uuid_relabel],
      },
      {
        'job_name'        => 'trafficserver-text',
        'file_sd_configs' => [
          { 'files' => ["${targets_path}/trafficserver-text_*.yaml"] },
        ],
      },
      {
        'job_name'        => 'trafficserver-upload',
        'file_sd_configs' => [
          { 'files' => ["${targets_path}/trafficserver-upload_*.yaml"] },
        ],
      },
    ]

    $ipmi_jobs = [
      {
        'job_name'        => 'ipmi',
        'file_sd_configs' => [
          { 'files' => ["${targets_path}/ipmi_*.yaml"] },
        ],
      },
    ]

    prometheus::ganeti { 'ganeti':
        dest     => "${targets_path}/ganeti_${::site}.yaml",
        clusters => $ganeti_clusters,
    }

    $ganeti_jobs = [
      {
        'job_name'        => 'ganeti',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/ganeti_*.yaml" ]}
        ],
      },
    ]

    # Pull varnish-related metrics generated via varnishmtail (default instance)
    prometheus::class_config{ "varnish-upload_mtail_${::site}":
        dest       => "${targets_path}/varnish-upload_mtail_${::site}.yaml",
        class_name => 'role::cache::upload',
        port       => 3903,
    }
    prometheus::class_config{ "varnish-upload_haproxy_mtail_${::site}":
        dest       => "${targets_path}/varnish-upload_haproxy_mtail_${::site}.yaml",
        class_name => 'role::cache::upload_haproxy',
        port       => 3903,
    }
    prometheus::class_config{ "varnish-upload_envoy_mtail_${::site}":
        dest       => "${targets_path}/varnish-upload_envoy_mtail_${::site}.yaml",
        class_name => 'role::cache::upload_envoy',
        port       => 3903,
    }
    prometheus::class_config{ "varnish-text_mtail_${::site}":
        dest       => "${targets_path}/varnish-text_mtail_${::site}.yaml",
        class_name => 'role::cache::text',
        port       => 3903,
    }
    prometheus::class_config{ "varnish-text_haproxy_mtail_${::site}":
        dest       => "${targets_path}/varnish-text_haproxy_mtail_${::site}.yaml",
        class_name => 'role::cache::text_haproxy',
        port       => 3903,
    }
    prometheus::class_config{ "varnish-text_envoy_mtail_${::site}":
        dest       => "${targets_path}/varnish-text_envoy_mtail_${::site}.yaml",
        class_name => 'role::cache::text_envoy',
        port       => 3903,
    }

    # Pull varnish-related metrics generated via varnishmtail (internal instance)
    prometheus::class_config{ "varnish-upload_mtail_internal_${::site}":
        dest       => "${targets_path}/varnish-upload_mtail_internal_${::site}.yaml",
        class_name => 'role::cache::upload',
        port       => 3913,
    }
    prometheus::class_config{ "varnish-upload_haproxy_mtail_internal_${::site}":
        dest       => "${targets_path}/varnish-upload_haproxy_mtail_internal_${::site}.yaml",
        class_name => 'role::cache::upload_haproxy',
        port       => 3913,
    }
    prometheus::class_config{ "varnish-upload_envoy_mtail_internal_${::site}":
        dest       => "${targets_path}/varnish-upload_envoy_mtail_internal_${::site}.yaml",
        class_name => 'role::cache::upload_envoy',
        port       => 3913,
    }
    prometheus::class_config{ "varnish-text_mtail_internal_${::site}":
        dest       => "${targets_path}/varnish-text_mtail_internal_${::site}.yaml",
        class_name => 'role::cache::text',
        port       => 3913,
    }
    prometheus::class_config{ "varnish-text_haproxy_mtail_internal_${::site}":
        dest       => "${targets_path}/varnish-text_haproxy_mtail_internal_${::site}.yaml",
        class_name => 'role::cache::text_haproxy',
        port       => 3913,
    }
    prometheus::class_config{ "varnish-text_envoy_mtail_internal_${::site}":
        dest       => "${targets_path}/varnish-text_envoy_mtail_internal_${::site}.yaml",
        class_name => 'role::cache::text_envoy',
        port       => 3913,
    }

    # ATS origin server stats generated by mtail
    prometheus::class_config{ "trafficserver-upload_backendmtail_${::site}":
        dest       => "${targets_path}/trafficserver-upload_backendmtail_${::site}.yaml",
        class_name => 'role::cache::upload',
        port       => 3904,
    }
    prometheus::class_config{ "trafficserver-upload_haproxy_backendmtail_${::site}":
        dest       => "${targets_path}/trafficserver-upload_haproxy_backendmtail_${::site}.yaml",
        class_name => 'role::cache::upload_haproxy',
        port       => 3904,
    }
    prometheus::class_config{ "trafficserver-upload_envoy_backendmtail_${::site}":
        dest       => "${targets_path}/trafficserver-upload_envoy_backendmtail_${::site}.yaml",
        class_name => 'role::cache::upload_envoy',
        port       => 3904,
    }

    prometheus::class_config{ "trafficserver-text_backendmtail_${::site}":
        dest       => "${targets_path}/trafficserver-text_backendmtail_${::site}.yaml",
        class_name => 'role::cache::text',
        port       => 3904,
    }
    prometheus::class_config{ "trafficserver-text_haproxy_backendmtail_${::site}":
        dest       => "${targets_path}/trafficserver-text_haproxy_backendmtail_${::site}.yaml",
        class_name => 'role::cache::text_haproxy',
        port       => 3904,
    }
    prometheus::class_config{ "trafficserver-text_envoy_backendmtail_${::site}":
        dest       => "${targets_path}/trafficserver-text_envoy_backendmtail_${::site}.yaml",
        class_name => 'role::cache::text_envoy',
        port       => 3904,
    }

    # ats-tls TTFB metrics generated by mtail
    prometheus::class_config{ "trafficserver-upload_tlsmtail_${::site}":
        dest       => "${targets_path}/trafficserver-upload_tlsmtail_${::site}.yaml",
        class_name => 'role::cache::upload',
        port       => 3905,
    }

    prometheus::class_config{ "trafficserver-text_tlsmtail_${::site}":
        dest       => "${targets_path}/trafficserver-text_tlsmtail_${::site}.yaml",
        class_name => 'role::cache::text',
        port       => 3905,
    }

    # Job definition for trafficserver_exporter
    $trafficserver_jobs = [
      {
        'job_name'        => 'trafficserver',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/trafficserver_*.yaml"] },
        ],
      },
    ]

    prometheus::cluster_config{ "trafficserver_backend_text_${::site}":
        dest    => "${targets_path}/trafficserver_backend_text_${::site}.yaml",
        cluster => 'cache_text',
        port    => 9122,
        labels  => {
          'layer'   => 'backend',
          'cluster' => 'cache_text',
        }
    }
    prometheus::cluster_config{ "trafficserver_backend_upload_${::site}":
        dest    => "${targets_path}/trafficserver_backend_upload_${::site}.yaml",
        cluster => 'cache_upload',
        port    => 9122,
        labels  => {
          'layer'   => 'backend',
          'cluster' => 'cache_upload',
        }
    }
    prometheus::class_config{ "trafficserver_tls_text_${::site}":
        dest       => "${targets_path}/trafficserver_tls_text_${::site}.yaml",
        class_name => 'role::cache::text',
        port       => 9322,
        labels     => {
          'layer'   => 'tls',
          'cluster' => 'cache_text',
        }
    }
    prometheus::class_config{ "trafficserver_tls_upload_${::site}":
        dest       => "${targets_path}/trafficserver_tls_upload_${::site}.yaml",
        class_name => 'role::cache::upload',
        port       => 9322,
        labels     => {
          'layer'   => 'tls',
          'cluster' => 'cache_upload',
        }
    }

    $cache_haproxy_tls_jobs = [
      {
        'job_name'        => 'cache_haproxy_tls',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/cache_haproxy_tls_*.yaml"] },
        ],
      },
    ]

    prometheus::class_config{ "cache_haproxy_tls_upload_${::site}":
        dest       => "${targets_path}/cache_haproxy_tls_upload_${::site}.yaml",
        class_name => 'role::cache::upload_haproxy',
        port       => 9422,
        labels     => {
          'layer'   => 'tls',
          'cluster' => 'cache_upload',
        }
    }

    prometheus::class_config{ "cache_haproxy_tls_mtail_upload_${::site}":
        dest       => "${targets_path}/cache_haproxy_tls_mtail_upload_${::site}.yaml",
        class_name => 'role::cache::upload_haproxy',
        port       => 3906,
        labels     => {
            'layer'   => 'tls',
            'cluster' => 'cache_upload',
        }
    }

    prometheus::class_config{ "cache_haproxy_tls_text_${::site}":
        dest       => "${targets_path}/cache_haproxy_tls_text_${::site}.yaml",
        class_name => 'role::cache::text_haproxy',
        port       => 9422,
        labels     => {
          'layer'   => 'tls',
          'cluster' => 'cache_text',
        }
    }

    prometheus::class_config{ "cache_haproxy_tls_mtail_text_${::site}":
        dest       => "${targets_path}/cache_haproxy_tls_mtail_text_${::site}.yaml",
        class_name => 'role::cache::text_haproxy',
        port       => 3906,
        labels     => {
            'layer'   => 'tls',
            'cluster' => 'cache_text',
        }
    }

    $cache_envoy_jobs = [
        {
        'job_name'          => 'cache_envoy',
        'metrics_path'      => '/stats/prometheus',
        'scheme'            => 'http',
        'file_sd_configs'   => [
            { 'files' => [ "${targets_path}/cache_envoy_*.yaml" ]}
        ],
        },
    ]
    prometheus::class_config{ "cache_envoy_${::site}":
        dest       => "${targets_path}/cache_envoy_${::site}.yaml",
        class_name => 'profile::cache::envoy',
        port       => 9631,
    }

    # Job definition for purged
    $purged_jobs = [
      {
        'job_name'        => 'purged',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/purged_*.yaml"] },
        ],
        # rdkafka produces lots of metrics, keep only those we are interested in for purged
        'metric_relabel_configs' => [
          { 'source_labels' => ['__name__'],
            'regex'         => '^(purged_|go_|process_|rdkafka_consumer_(topics_partitions_msgs|msg_cnt|replyq|msg_size|brokers_txbytes|brokers_req_timeouts|brokers_txerrs|brokers_txretries|brokers_rxbytes|brokers_rxerrs|brokers_rtt_min|brokers_rtt_avg|brokers_rtt_max)).*$',
            'action'        => 'keep'
          },
        ]
      },
    ]

    # List of hosts running purged
    prometheus::class_config{ "purged_${::site}":
        dest       => "${targets_path}/purged_${::site}.yaml",
        class_name => 'purged',
        port       => 2112,
        labels     => {}
    }

    # Job definition for memcache_exporter
    $memcached_jobs = [
      {
        'job_name'        => 'memcached',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/memcached_*.yaml"] },
        ]
      },
    ]

    # Generate a list of hosts running memcached from wikimedia_clusters definition in Hiera
    prometheus::class_config{ "memcached_${::site}":
        dest       => "${targets_path}/memcached_${::site}.yaml",
        class_name => 'profile::prometheus::memcached_exporter',
        port       => 9150,
        labels     => {}
    }

    # Job definition for apache_exporter
    $apache_jobs = [
      {
        'job_name'        => 'apache',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/apache_*.yaml"] },
        ]
      },
    ]

    # Generate a list of hosts running apache from wikimedia_clusters definition in Hiera
    # TODO(filippo): generate the configuration based on hosts with apache class applied
    prometheus::cluster_config{ "apache_jobrunner_${::site}":
        dest    => "${targets_path}/apache_jobrunner_${::site}.yaml",
        cluster => 'jobrunner',
        port    => 9117,
        labels  => {
            'cluster' => 'jobrunner'
        }
    }
    prometheus::cluster_config{ "apache_appserver_${::site}":
        dest    => "${targets_path}/apache_appserver_${::site}.yaml",
        cluster => 'appserver',
        port    => 9117,
        labels  => {
            'cluster' => 'appserver'
        }
    }
    prometheus::cluster_config{ "apache_api_appserver_${::site}":
        dest    => "${targets_path}/apache_api_appserver_${::site}.yaml",
        cluster => 'api_appserver',
        port    => 9117,
        labels  => {
            'cluster' => 'api_appserver'
        }
    }

    # Special config for Apache on Piwik deployments
    prometheus::class_config{ "apache_piwik_${::site}":
        dest       => "${targets_path}/apache_piwik_${::site}.yaml",
        class_name => 'profile::piwik::webserver',
        port       => 9117,
    }

    # Special config for Apache on Superset deployments
    prometheus::class_config{ "apache_superset_${::site}":
        dest       => "${targets_path}/apache_superset_${::site}.yaml",
        class_name => 'profile::superset::proxy',
        port       => 9117,
    }

    # Special config for Apache on VRTS deployment
    prometheus::class_config{ "apache_vrts_${::site}":
        dest       => "${targets_path}/apache_vrts_${::site}.yaml",
        class_name => 'profile::vrts',
        port       => 9117,
    }

    # Special config for Apache on Phabricator deployment
    prometheus::class_config{ "apache_phabricator_${::site}":
        dest       => "${targets_path}/apache_phabricator_${::site}.yaml",
        class_name => 'profile::phabricator::main',
        port       => 9117,
    }

    # Special config for Apache on Gerrit deployment
    prometheus::class_config{ "apache_gerrit_${::site}":
        dest       => "${targets_path}/apache_gerrit_${::site}.yaml",
        class_name => 'role::gerrit',
        port       => 9117,
    }

    # Special config for Apache on CI master
    prometheus::class_config{ "apache_ci_${::site}":
        dest       => "${targets_path}/apache_ci_master_${::site}.yaml",
        class_name => 'role::ci::master',
        port       => 9117,
    }

    # Job definition for icinga_exporter
    $icinga_jobs = [
      {
        'job_name'        => 'icinga',
        'scrape_timeout'  => '20s',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/icinga_*.yaml" ]}
        ],
      },
      {
        'job_name'        => 'icinga-am',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/icinga-am_*.yaml" ]}
        ],
      },
    ]

    # Special config for Icinga exporter
    prometheus::class_config{ "icinga_${::site}":
        dest       => "${targets_path}/icinga_${::site}.yaml",
        class_name => 'profile::icinga',
        port       => 9245,
    }

    prometheus::class_config{ "icinga-am_${::site}":
        dest             => "${targets_path}/icinga-am_${::site}.yaml",
        class_name       => 'prometheus::icinga_exporter',
        class_parameters => { 'export_problems' => true },
        port             => 9247,
    }

    # Job definition for prometheus-es-exporter
    $es_exporter_jobs = [
        {
            'job_name'        => 'es_exporter',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/es_exporter_*.yaml" ]}
            ],
        },
    ]

    # Special config for prometheus-es-exporter
    prometheus::class_config { "es_exporter_${::site}":
        dest       => "${targets_path}/es_exporter_${::site}.yaml",
        class_name => 'profile::prometheus::es_exporter',
        port       => 9206
    }

    # Job definition for udpmxircecho
    $udpmxircecho_jobs = [
        {
            'job_name'        => 'udpmxircecho',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/udpmxircecho_*.yaml" ] },
            ],
        },
    ]
    prometheus::class_config { "udpmxircecho_${::site}":
        dest       => "${targets_path}/udpmxircecho_${::site}.yaml",
        class_name => 'mw_rc_irc::irc_echo',
        port       => 9221
    }

    # Job definition for alertmanager
    $alertmanager_jobs = [
      {
        'job_name'        => 'alertmanager',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/alertmanager_*.yaml"] },
        ],
      },
    ]

    prometheus::class_config{ "alertmanager_${::site}":
        dest       => "${targets_path}/alertmanager_${::site}.yaml",
        class_name => 'profile::alertmanager',
        port       => 9093,
    }

    prometheus::class_config{ "alertmanager_irc_${::site}":
        dest             => "${targets_path}/alertmanager_irc_${::site}.yaml",
        class_name       => 'alertmanager::irc',
        class_parameters => { 'service_ensure' => running },
        port             => 19190,
    }

    prometheus::class_config{ "alertmanager_web_${::site}":
        dest       => "${targets_path}/alertmanager_web_${::site}.yaml",
        class_name => 'profile::alertmanager::web',
        port       => 19194,
    }

    prometheus::class_config{ "alertmanager_ack_${::site}":
        dest       => "${targets_path}/alertmanager_ack_${::site}.yaml",
        class_name => 'profile::alertmanager::ack',
        port       => 19195,
    }

    prometheus::class_config{ "alertmanager_phab_${::site}":
        dest       => "${targets_path}/alertmanager_phab_${::site}.yaml",
        class_name => 'profile::alertmanager::phab',
        port       => 8292,
    }

    # Job definition for alertmanager
    $pushgateway_jobs = [
      {
        'job_name'        => 'pushgateway',
        'honor_labels'    => true,
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/pushgateway_*.yaml"] },
        ],
      },
    ]

    prometheus::class_config{ "pushgateway_${::site}":
        dest             => "${targets_path}/pushgateway_${::site}.yaml",
        class_name       => 'prometheus::pushgateway',
        port             => 9091,
        class_parameters => { 'ensure' => present },
    }

    # Job definition for cadvisor exporter
    $cadvisor_jobs = [
      {
        'job_name'        => 'cadvisor',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/cadvisor_*.yaml"] },
        ]
      },
    ]

    prometheus::class_config{ "cadvisor_${::site}":
        dest       => "${targets_path}/cadvisor_${::site}.yaml",
        class_name => 'profile::prometheus::cadvisor_exporter',
        port       => 4194,
        labels     => {}
    }

    # Job definition for varnishkafka exporter
    $varnishkafka_jobs = [
      {
        'job_name'        => 'varnishkafka',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/varnishkafka_*.yaml" ]}
        ],
      }
    ]

    # Special config for varnishkafka exporter
    prometheus::class_config{ "varnishkafka_${::site}":
        dest       => "${targets_path}/varnishkafka_${::site}.yaml",
        class_name => 'profile::prometheus::varnishkafka_exporter',
        port       => 9132,
    }

    # Job definition for etcd_exporter
    $etcd_jobs = [
      {
        'job_name'        => 'etcd',
        'scheme'          => 'https',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/etcd_*.yaml" ]}
        ],
      },
    ]

    $etcdmirror_jobs = [
      {
        'job_name'        => 'etcdmirror',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/etcdmirror_*.yaml" ]}
        ],
      },
    ]

    # Gather etcd metrics from machines exposing them via http
    prometheus::class_config{ "etcd_servers_${::site}":
        dest       => "${targets_path}/etcd_${::site}.yaml",
        class_name => 'role::configcluster',
        port       => 4001,
    }

    # Gather replication stats where etcd-mirror is running.
    prometheus::class_config{ "etcdmirror_${::site}":
        dest             => "${targets_path}/etcdmirror_${::site}.yaml",
        class_name       => 'profile::etcd::replication',
        class_parameters => {
            'active' => true
        },
        port             => 8000,
    }

    # kubernetes etcd. TODO: Investigate whether all of these can be merged with
    # the above using ::profile::etcd::v3. But this requires conf200X hosts
    # first to be upgraded
    prometheus::class_config{ "kubetcd_${::site}":
        dest           => "${targets_path}/kubetcd_${::site}.yaml",
        class_name     => 'role::etcd::v3::kubernetes',
        port           => 2379,
        hostnames_only => false,
    }
    prometheus::class_config{ "kubetcd_staging_${::site}":
        dest           => "${targets_path}/kubetcd_staging_${::site}.yaml",
        class_name     => 'role::etcd::v3::kubernetes::staging',
        port           => 2379,
        hostnames_only => false,
    }
    $kubetcd_jobs = [
      {
        'job_name'        => 'kubetcd',
        'scheme'          => 'https',
        'file_sd_configs' => [
          { 'files' => [
              "${targets_path}/kubetcd_*.yaml",
              ],}
        ],
      },
    ]

    prometheus::class_config{ "ml_etcd_${::site}":
        dest           => "${targets_path}/ml_etcd_${::site}.yaml",
        class_name     => 'role::etcd::v3::ml_etcd',
        port           => 2379,
        hostnames_only => false,
    }

    $ml_etcd_jobs = [
      {
        'job_name'        => 'ml_etcd',
        'scheme'          => 'https',
        'file_sd_configs' => [
          { 'files' => [
              "${targets_path}/ml_etcd_*.yaml",
              ],}
        ],
      },
    ]

    # mcrouter
    # Job definition for mcrouter_exporter
    $mcrouter_jobs = [
      {
        'job_name'        => 'mcrouter',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/mcrouter_*.yaml" ]}
        ],
      },
    ]
    prometheus::class_config{ "mcrouter_${::site}":
        dest       => "${targets_path}/mcrouter_${::site}.yaml",
        class_name => 'profile::prometheus::mcrouter_exporter',
        port       => 9151,
    }

    # php
    $php_jobs =  [
        {
        'job_name'        => 'php',
        'scheme'          => 'http',
        'file_sd_configs' => [
            { 'files' => [ "${targets_path}/php_*.yaml" ]}
        ],
        },
    ]

    prometheus::class_config{ "php_${::site}":
        dest       => "${targets_path}/php_${::site}.yaml",
        class_name => 'profile::mediawiki::php::monitoring',
        port       => 9181,
    }

    # envoy proxy
    $envoy_jobs = [
        {
        'job_name'          => 'envoy',
        'metrics_path'      => '/stats/prometheus',
        'scheme'            => 'http',
        'file_sd_configs'   => [
            { 'files' => ["${targets_path}/envoy_*.yaml"] }
        ],
        # Envoy produces a ton of metrics, but for now we're just interested in
        # upstream and downstream requests latencies and counts, as well as connection
        # stats. So just keep those and nothing else.
        'metric_relabel_configs' => [
          { 'source_labels' => ['__name__'],
            'regex'         => '^envoy_(http_down|cluster_up)stream_(rq|cx).*$',
            'action'        => 'keep'
          },
        ]
        },
    ]
    prometheus::class_config{ "envoy_${::site}":
        dest       => "${targets_path}/envoy_${::site}.yaml",
        class_name => 'profile::envoy',
        port       => 9631,
    }

    $pdu_jobs = [
      {
        'job_name'        => 'pdu',
        'metrics_path'    => '/snmp',
        # PDUs with per-outlet control can take a long time to be scraped
        'scrape_timeout'  => '45s',
        'params'          => {
          'module' => [ "pdu_${::site}" ],
        },
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/pdu_sentry3_*.yaml" ] }
        ],
        'relabel_configs' => [
          { 'source_labels' => ['__address__'],
            'target_label'  => '__param_target',
          },
          { 'source_labels' => ['__param_target'],
            'target_label'  => 'instance',
          },
          { 'target_label' => '__address__',
            'replacement'  => "${netmon_server}:9116",
          },
        ],
        # Prefix all metrics with pdu_ (except snmp_ from snmp_exporter itself)
        # Saves having to tweak the yaml files from snmp-exporter generator
        # https://github.com/prometheus/snmp_exporter/tree/master/generator
        'metric_relabel_configs' => [
          { 'source_labels' => ['__name__'],
            'regex'         => '(^([^s]|s($|[^n]|n($|[^m]|m($|[^p]|p($|[^_]))))).*$)',
            'target_label'  => '__name__',
            'replacement'   => 'pdu_$0',
          },
        ],
      },
      {
        'job_name'        => 'pdu_sentry4',
        'metrics_path'    => '/snmp',
        # PDUs with per-outlet control can take a long time to be scraped
        'scrape_timeout'  => '45s',
        'params'          => {
          'module' => [ "pdu_sentry4_${::site}" ],
        },
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/pdu_sentry4_*.yaml" ] }
        ],
        'relabel_configs' => [
          { 'source_labels' => ['__address__'],
            'target_label'  => '__param_target',
          },
          { 'source_labels' => ['__param_target'],
            'target_label'  => 'instance',
          },
          { 'target_label' => '__address__',
            'replacement'  => "${netmon_server}:9116",
          },
        ],
        # Prefix all metrics with pdu_ (except snmp_ from snmp_exporter itself)
        # Saves having to tweak the yaml files from snmp-exporter generator
        # https://github.com/prometheus/snmp_exporter/tree/master/generator
        'metric_relabel_configs' => [
          { 'source_labels' => ['__name__'],
            'regex'         => '(^([^s]|s($|[^n]|n($|[^m]|m($|[^p]|p($|[^_]))))).*$)',
            'target_label'  => '__name__',
            'replacement'   => 'pdu_$0',
          },
        ],
      },
    ]

    prometheus::pdu_config { "pdu_sentry3_${::site}":
        dest => "${targets_path}/pdu_sentry3_${::site}.yaml",
    }

    prometheus::pdu_config { "pdu_sentry4_${::site}":
        dest  => "${targets_path}/pdu_sentry4_${::site}.yaml",
        model => 'sentry4',
    }

    # PoPs might have single phase PDUs (e.g. ulsfo)
    prometheus::pdu_config { "pdu_sentry4_1phase_${::site}":
        dest     => "${targets_path}/pdu_sentry4_1phase_${::site}.yaml",
        model    => 'sentry4',
        resource => 'Facilities::Monitor_pdu_1phase',
    }

    # T221099
    $docker_registry_jobs = [
      {
        'job_name'        => 'docker-registry',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/docker_registry_*.yaml" ]}
        ],
      },
    ]

    prometheus::class_config{ "docker_registry_${::site}":
        dest       => "${targets_path}/docker_registry_${::site}.yaml",
        class_name => 'profile::docker_registry_ha::registry',
        port       => 5001,
    }

    $routinator_jobs = [
      {
        'job_name'        => 'routinator',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/routinator_*.yaml" ]}
        ],
      },
    ]

    prometheus::class_config{ "routinator_${::site}":
        dest       => "${targets_path}/routinator_${::site}.yaml",
        class_name => 'role::rpkivalidator',
        port       => 9556,
    }

    $squid_jobs = [
      {
        'job_name'        => 'squid',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/squid_*.yaml" ]}
        ],
      },
    ]

    prometheus::class_config{ "squid_${::site}":
        dest       => "${targets_path}/squid_${::site}.yaml",
        class_name => 'profile::prometheus::squid_exporter',
        port       => 9301,
    }

    $bird_jobs = [
      {
        'job_name'        => 'bird',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/bird_*.yaml" ]}
        ],
      },
    ]

    prometheus::class_config{ "bird_${::site}":
        dest       => "${targets_path}/bird_${::site}.yaml",
        class_name => 'profile::bird::anycast',
        port       => 9324,
    }

    # Job definition for pybal
    $pybal_jobs = [
      {
        'job_name'        => 'pybal',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/pybal_*.yaml" ]}
        ],
      },
    ]

    prometheus::class_config{ "pybal_${::site}":
        dest       => "${targets_path}/pybal_${::site}.yaml",
        class_name => 'role::lvs::balancer',
        port       => 9090,
    }

    $jmx_exporter_jobs = [
      {
        'job_name'        => 'jmx_logstash',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/jmx_logstash_*.yaml" ]}
        ],
      },
      {
        'job_name'        => 'jmx_kafka',
        'scheme'          => 'http',
        'scrape_timeout'  => '45s',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/jmx_kafka_broker_*.yaml" ]}
        ],
      },
      {
        'job_name'        => 'jmx_kafka_mirrormaker',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/jmx_kafka_mirrormaker_*.yaml" ]}
        ],
      },
      {
        'job_name'        => 'jmx_puppetdb',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/jmx_puppetdb_*.yaml" ]}
        ],
      },
      {
        'job_name'        => 'jmx_wcqs_blazegraph',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/jmx_wcqs_blazegraph_*.yaml" ]}
        ],
      },
      {
        'job_name'        => 'jmx_wdqs_blazegraph',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/jmx_wdqs_blazegraph_*.yaml" ]}
        ],
      },
      {
        'job_name'        => 'jmx_wdqs_updater',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/jmx_wdqs_updater_*.yaml" ]}
        ],
      },
      {
        'job_name'        => 'jmx_query_service_streaming_updater',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/jmx_query_service_streaming_updater_*.yaml" ]}
        ],
      },
      {
        'job_name'        => 'jmx_zookeeper',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/jmx_zookeeper_*.yaml" ]}
        ],
      },
    ]

    prometheus::jmx_exporter_config{ "logstash_${::site}":
        dest       => "${targets_path}/jmx_logstash_${::site}.yaml",
        class_name => 'logstash',
    }

    # Collect all declared kafka_broker_.* jmx_exporter_instances
    # from any uses of profile::kafka::broker::monitoring.
    prometheus::jmx_exporter_config{ "kafka_broker_${::site}":
        dest              => "${targets_path}/jmx_kafka_broker_${::site}.yaml",
        class_name        => 'profile::kafka::broker::monitoring',
        instance_selector => 'kafka_broker_.*',
    }
    # Collect all declared kafka_mirror_.* jmx_exporter_instances
    # from any uses of profile::kafka::mirror.
    prometheus::jmx_exporter_config{ "kafka_mirrormaker_${::site}":
        dest              => "${targets_path}/jmx_kafka_mirrormaker_${::site}.yaml",
        class_name        => 'profile::kafka::mirror',
        instance_selector => 'kafka_mirror_.*',
    }

    prometheus::jmx_exporter_config{ "puppetdb_${::site}":
        dest       => "${targets_path}/jmx_puppetdb_${::site}.yaml",
        class_name => 'role::puppetdb',
    }

    prometheus::jmx_exporter_config{ "wcqs_blazegraph_${::site}":
        dest              => "${targets_path}/jmx_wcqs_blazegraph_${::site}.yaml",
        class_name        => 'profile::query_service::wcqs',
        instance_selector => 'wcqs-blazegraph',
    }

    prometheus::jmx_exporter_config{ "wdqs_blazegraph_${::site}":
        dest              => "${targets_path}/jmx_wdqs_blazegraph_${::site}.yaml",
        class_name        => 'profile::query_service::wikidata',
        instance_selector => 'wdqs-blazegraph',
    }

    prometheus::jmx_exporter_config { "query_service_streaming_updater_${::site}":
        dest              => "${targets_path}/jmx_query_service_streaming_updater_${::site}.yaml",
        class_name        => 'profile::query_service::streaming_updater',
        instance_selector => '.*-updater',
    }

    prometheus::jmx_exporter_config{ "zookeeper_${::site}":
        dest       => "${targets_path}/jmx_zookeeper_${::site}.yaml",
        class_name => 'role::configcluster',
        labels     => {
            'cluster' => "main-${::site}",
        },
    }

    prometheus::jmx_exporter_config{ "zookeeper_test_${::site}":
        dest       => "${targets_path}/jmx_zookeeper_test_${::site}.yaml",
        class_name => 'role::zookeeper::test',
        labels     => {
            'cluster' => "test-${::site}",
        },
    }

    $etherpad_jobs = [
      {
        'job_name'        => 'etherpad',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/etherpad_*.yaml" ]}
        ],
      },
    ]

    prometheus::class_config{ "etherpad_${::site}":
        dest       => "${targets_path}/etherpad_${::site}.yaml",
        class_name => 'role::etherpad',
        port       => 9198,
    }

    $blazegraph_jobs = [
      {
        'job_name'        => 'blazegraph',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/blazegraph_*.yaml" ]}
        ],
      },
    ]

    prometheus::resource_config{ "blazegraph_${::site}":
        dest           => "${targets_path}/blazegraph_${::site}.yaml",
        define_name    => 'prometheus::blazegraph_exporter',
        port_parameter => 'prometheus_port'
    }

    # redis_exporter runs alongside each redis instance, thus drop the (uninteresting in this
    # case) 'addr' and 'alias' labels
    $redis_exporter_relabel = {
      'regex'  => '(addr|alias)',
      'action' => 'labeldrop',
    }

    # Configure one job per redis multidc 'category', plus redis for maps.
    $redis_jobs = [
      {
        'job_name'        => 'redis_sessions',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/redis_sessions_*.yaml" ]}
        ],
        'metric_relabel_configs' => [ $redis_exporter_relabel ],
      },
      {
        'job_name'        => 'redis_misc',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/redis_misc_*.yaml" ]}
        ],
        'metric_relabel_configs' => [ $redis_exporter_relabel ],
      },
      {
        'job_name'        => 'redis_maps',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/redis_maps_*.yaml" ]}
        ],
        'metric_relabel_configs' => [ $redis_exporter_relabel ],
      },
      {
        'job_name'        => 'redis_ores',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/redis_ores_*.yaml" ]}
        ],
        'metric_relabel_configs' => [ $redis_exporter_relabel ],
      },
    ]

    prometheus::redis_exporter_config{ "redis_sessions_${::site}":
        dest       => "${targets_path}/redis_sessions_${::site}.yaml",
        class_name => 'role::mediawiki::memcached',
    }

    prometheus::redis_exporter_config{ "redis_misc_master_${::site}":
        dest       => "${targets_path}/redis_misc_master_${::site}.yaml",
        class_name => 'role::redis::misc::master',
    }

    prometheus::redis_exporter_config{ "redis_misc_slave_${::site}":
        dest       => "${targets_path}/redis_misc_slave_${::site}.yaml",
        class_name => 'role::redis::misc::slave',
    }

    prometheus::redis_exporter_config{ "redis_maps_${::site}":
        dest       => "${targets_path}/redis_maps_${::site}.yaml",
        class_name => 'role::maps::master',
    }

    prometheus::redis_exporter_config{ "redis_ores_${::site}":
        dest       => "${targets_path}/redis_ores_${::site}.yaml",
        class_name => 'role::ores::redis',
    }

    $mtail_jobs = [
      {
        'job_name'        => 'mtail',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/mtail_*.yaml" ]}
        ],
      },
    ]

    prometheus::class_config{ "mtail_mx_${::site}":
        dest       => "${targets_path}/mtail_mx_${::site}.yaml",
        class_name => 'role::mail::mx',
        port       => 3903,
    }

    prometheus::class_config{ "mtail_syslog_${::site}":
        dest       => "${targets_path}/mtail_syslog_${::site}.yaml",
        class_name => 'role::syslog::centralserver',
        port       => 3903,
    }

    prometheus::class_config{ "mtail_thumbor_haproxy_${::site}":
        dest       => "${targets_path}/mtail_thumbor_haproxy_${::site}.yaml",
        class_name => 'role::thumbor::mediawiki',
        port       => 3903,
    }

    prometheus::class_config{ "mtail_mediawiki_apache_${::site}":
        dest       => "${targets_path}/mtail_mediawiki_webserver_${::site}.yaml",
        class_name => 'profile::mediawiki::webserver',
        port       => 3903,
    }

    prometheus::class_config{ "mtail_lists_server_${::site}":
        dest       => "${targets_path}/mtail_lists_server_${::site}.yaml",
        class_name => 'profile::lists',
        port       => 3903,
    }

    prometheus::class_config{ "mtail_zuul_${::site}":
        dest       => "${targets_path}/mtail_zuul_${::site}.yaml",
        class_name => 'profile::zuul::server',
        port       => 3903,
    }

    $ldap_jobs = [
      {
        'job_name'        => 'ldap',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/ldap_*.yaml" ]}
        ],
      },
    ]

    prometheus::class_config{ "ldap_${::site}":
        dest       => "${targets_path}/ldap_${::site}.yaml",
        class_name => 'role::openldap::rw',
        port       => 9142,
    }

    $logstash_jobs= [
        {
            'job_name'        => 'logstash',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/logstash_*.yaml" ]}
            ],
            # logstash auto-generates long random plugin_ids by default, so
            # drop plugin_ids matching the default random plugin_id format
            'metric_relabel_configs' => [
                { 'source_labels' => ['plugin_id'],
                    'regex'  => '(\w{40}-\d+)',
                    'action' => 'drop',
                },
                # Logstash 7 plugin IDs
                { 'source_labels' => ['plugin_id'],
                    'regex'  => '(\w{64})',
                    'action' => 'drop',
                },
            ],
        },
    ]
    prometheus::class_config { "logstash_${::site}":
        dest       => "${targets_path}/logstash_${::site}.yaml",
        class_name => 'profile::prometheus::logstash_exporter',
        port       => 9198,
    }

    $rsyslog_jobs = [
        {
            'job_name'        => 'rsyslog',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/rsyslog_*.yaml" ]}
            ],
            # drop metrics for actions without an explicity assigned name
            # to prevent metrics explosion
            'metric_relabel_configs' => [
                { 'source_labels' => ['action'],
                    'regex'  => 'action-\d+-.*(?:.*)',
                    'action' => 'drop',
                },
            ],
        },
    ]
    prometheus::class_config { "rsyslog_${::site}":
        dest       => "${targets_path}/rsyslog_${::site}.yaml",
        class_name => 'profile::prometheus::rsyslog_exporter',
        port       => 9105,
    }

    $pdns_rec_jobs = [
      {
        'job_name'        => 'pdnsrec',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/pdnsrec_*.yaml" ]}
        ],
      },
    ]

    prometheus::class_config{ "pdnsrec_${::site}":
        dest       => "${targets_path}/pdnsrec_${::site}.yaml",
        class_name => 'profile::dns::recursor',
        port       => 9199,
    }

    $elasticsearch_jobs = [
        {
            'job_name'        => 'elasticsearch',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/elasticsearch_*.yaml" ]}
            ],
        },
    ]
    prometheus::resource_config { "elasticsearch_${::site}":
        dest           => "${targets_path}/elasticsearch_${::site}.yaml",
        define_name    => 'prometheus::elasticsearch_exporter',
        port_parameter => 'prometheus_port',
    }

    $wmf_elasticsearch_jobs = [
        {
            'job_name'        => 'wmf_elasticsearch',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/wmf_elasticsearch_*.yaml" ]}
            ],
        },
    ]
    prometheus::resource_config { "wmf_elasticsearch_${::site}":
        dest           => "${targets_path}/wmf_elasticsearch_${::site}.yaml",
        define_name    => 'prometheus::wmf_elasticsearch_exporter',
        port_parameter => 'prometheus_port',
    }

    # Job definition for haproxy_exporter
    $haproxy_jobs = [
      {
        'job_name'        => 'haproxy',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/haproxy_*.yaml"] },
        ],
      },
    ]

    prometheus::class_config{ "haproxy_${::site}":
        dest       => "${targets_path}/haproxy_${::site}.yaml",
        class_name => 'profile::prometheus::haproxy_exporter',
        port       => 9901,
    }

    $statsd_exporter_jobs = [
      {
        'job_name'        => 'statsd_exporter',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/statsd_exporter_*.yaml"] },
        ],
      },
    ]

    prometheus::class_config{ "statsd_exporter_${::site}":
        dest       => "${targets_path}/statsd_exporter_${::site}.yaml",
        class_name => 'profile::prometheus::statsd_exporter',
        port       => 9112,
    }

    $nutcracker_jobs = [
        {
            'job_name'        => 'nutcracker',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/nutcracker_*.yaml" ]}
            ],
        },
    ]
    prometheus::class_config { "nutcracker_${::site}":
        dest       => "${targets_path}/nutcracker_${::site}.yaml",
        class_name => 'profile::prometheus::nutcracker_exporter',
        port       => 9191,
    }

    # Gather postgresql metrics from hosts having the
    # prometheus::postgres_exporter class defined
    $postgresql_jobs = [
      {
        'job_name'        => 'postgresql',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/postgresql_*.yaml" ]}
        ],
      },
    ]
    prometheus::class_config{ "postgresql_${::site}":
        dest       => "${targets_path}/postgresql_${::site}.yaml",
        class_name => 'prometheus::postgres_exporter',
        port       => 9187,
    }

    $kafka_burrow_jobs = [
      {
        'job_name'        => 'burrow',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/burrow_*.yaml" ]}
        ],
      },
    ]

    prometheus::class_config{ "burrow_main_${::site}":
        dest       => "${targets_path}/burrow_main_${::site}.yaml",
        class_name => 'role::kafka::monitoring_buster',
        port       => 9500,
    }

    prometheus::class_config{ "burrow_logging_${::site}":
        dest       => "${targets_path}/burrow_logging_${::site}.yaml",
        class_name => 'role::kafka::monitoring_buster',
        port       => 9501,
    }

    prometheus::class_config{ "burrow_jumbo_${::site}":
        dest       => "${targets_path}/burrow_jumbo_${::site}.yaml",
        class_name => 'role::kafka::monitoring_buster',
        port       => 9700,
    }

    $mjolnir_jobs = [
        {
            'job_name'        => 'mjolnir',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files'     => [ "${targets_path}/mjolnir_*.yaml" ]}
            ],
        },
    ]
    prometheus::class_config { "mjolnir_bulk_${::site}}.yaml":
        dest       => "${targets_path}/mjolnir_bulk_${::site}.yaml",
        class_name => 'role::search::loader',
        port       => 9170,
    }
    prometheus::resource_config { "mjolnir_kafka_msearch_daemon_instance_${::site}":
      dest           => "${targets_path}/mjolnir_kafka_msearch_daemon_instance_${::site}.yaml",
      define_name    => 'profile::mjolnir::kafka_msearch_daemon_instance',
      port_parameter => 'prometheus_port',
    }

    $ncredir_jobs = [
        {
            'job_name'        => 'ncredir',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files'     => [ "${targets_path}/ncredir_*.yaml" ]}
            ],
        },
    ]
    prometheus::class_config { "ncredir_access_log_${::site}.yaml":
        dest       => "${targets_path}/ncredir_access_log_${::site}.yaml",
        class_name => 'profile::ncredir',
        port       => 3904,
    }

    $ipsec_jobs= [
        {
            'job_name'        => 'ipsec',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/ipsec_*.yaml" ]}
            ],
        },
    ]
    prometheus::class_config { "ipsec_${::site}":
        dest       => "${targets_path}/ipsec_${::site}.yaml",
        class_name => 'profile::prometheus::ipsec_exporter',
        port       => 9536,
    }

    # cloud-dev metrics
    #
    #  Currently we don't have a prometheus host for codfw1dev, so adding these metrics to
    #   codfwdev for now.
    #
    #  (Be sure to check for naming collisions when adding things here; we don't want cloud-dev metrics
    #   showing up on production dashboards)
    $cloud_dev_pdns_jobs = [
        {
            'job_name'        => 'cloud_dev_pdns',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/cloud-dev-pdns_*.yaml" ] }
            ],
        },
    ]

    prometheus::class_config{ "cloud_dev_pdns_${::site}":
        dest       => "${targets_path}/cloud-dev-pdns_${::site}.yaml",
        class_name => 'role::wmcs::openstack::codfw1dev::services',
        port       => 8081,
    }

    $cloud_dev_pdns_rec_jobs = [
        {
            'job_name'        => 'cloud_dev_pdns_rec',
            'scheme'          => 'http',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/cloud-dev-pdns-rec_*.yaml" ] }
            ],
        },
    ]

    prometheus::class_config{ "cloud-dev-pdns-rec_${::site}":
        dest       => "${targets_path}/cloud-dev-pdns-rec_${::site}.yaml",
        class_name => 'role::wmcs::openstack::codfw1dev::services',
        port       => 8082,
    }

    # jobs for the bacula exporter (stats about executed production backups,
    # used and available, resources, etc.
    # Normally there would be only a single director on the primary datacenter,
    # but it can be switched over to the secondary, and in the future there may
    # be more than 1 active at the same time
    # Because it can take a long time to run, decrease the frequency and timeout.
    $bacula_jobs = [
        {
            'job_name'        => 'bacula',
            'scheme'          => 'http',
            'scrape_timeout'  => '60s',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/bacula_*.yaml" ] }
            ],
        },
    ]

    prometheus::class_config{ "bacula_${::site}":
        dest       => "${targets_path}/bacula_${::site}.yaml",
        class_name => 'role::backup',
        port       => 9133,
    }

    $poolcounter_exporter_jobs = [
      {
        'job_name'        => 'poolcounter_exporter',
        'scheme'          => 'http',
        'metrics_path'    => '/prometheus',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/poolcounter_exporter_*.yaml" ]}
        ],
      },
    ]

    prometheus::class_config{ "poolcounter_exporter_${::site}":
        dest       => "${targets_path}/poolcounter_exporter_${::site}.yaml",
        class_name => 'role::poolcounter::server',
        port       => 9106,
    }

    $atlas_exporter_jobs = [
      {
        'job_name'        => 'atlas_exporter',
        'scheme'          => 'http',
        'scrape_timeout'  => '30s',  # Pulling lots of RIPE mesurements takes > 10s
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/atlas_exporter_*.yaml" ]}
        ],
      },
    ]

    prometheus::class_config{ "atlas_exporter_${::site}":
        dest       => "${targets_path}/atlas_exporter_${::site}.yaml",
        class_name => 'profile::atlasexporter',
        port       => 9107,
    }

    $nic_saturation_exporter_jobs = [
      {
        'job_name'        => 'nic_saturation',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/nic_saturation_*.yaml" ]}
        ],
      },
    ]

    prometheus::class_config{ "nic_saturation_${::site}":
        dest             => "${targets_path}/nic_saturation_${::site}.yaml",
        port             => 9710,
        class_name       => 'profile::prometheus::nic_saturation_exporter',
        class_parameters => {
            'ensure' => 'present'
        },
    }

    $apereo_cas_jobs = [
        {
            'job_name'        => 'idp',
            'metrics_path'    => '/api/prometheus',
            'scheme'          => 'https',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/apereo_cas_exporter_${::site}.yaml" ] }
            ],
            'tls_config'        => {
                'server_name'   => 'idp.wikimedia.org',
            },
        }
    ]
    prometheus::class_config { "apereo_cas_exporter_${::site}":
        dest       => "${targets_path}/apereo_cas_exporter_${::site}.yaml",
        class_name => 'role::idp',
        port       => 443,
    }

    # Find instances of prometheus::blackbox_check_endpoint
    $blackbox_check_endpoint_jobs_query = [
        'AND',
        ['=', 'type', 'Prometheus::Blackbox_check_endpoint'],
        ['=', 'parameters.site', $::site]
    ]
    $blackbox_check_endpoint_jobs_raw = query_resources(false, $blackbox_check_endpoint_jobs_query, false)

    # Build config from the returned resource parameters
    $exported_blackbox_jobs = $blackbox_check_endpoint_jobs_raw.map |$job| {
        {
            'job_name'        => "swagger_${job['parameters']['job_name']}",
            'scrape_timeout'  => "${job['parameters']['timeout']}s",
            'static_configs'  => [{'targets' => $job['parameters']['targets']}],
            'params'          => $job['parameters']['params'],
            'metrics_path'    => $job['parameters']['metrics_path'],
            'relabel_configs' => $job['parameters']['relabel_configs']
        }
    }

    # Jobs maintained by perf-team:
    $webperf_jobs = [
      {
        'job_name'        => 'webperf_navtiming',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/webperf_navtiming_*.yaml" ]}
        ],
      }, {
        'job_name'        => 'webperf_arclamp',
        'scheme'          => 'http',
        'metrics_path'    => '/arclamp/metrics',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/webperf_arclamp_*.yaml" ]}
        ],
      },
    ]
    prometheus::class_config{ "webperf_navtiming_${::site}":
        dest       => "${targets_path}/webperf_navtiming_${::site}.yaml",
        class_name => 'profile::webperf::processors',
        port       => 9230,
    }
    prometheus::class_config{ "webperf_arclamp_${::site}":
        dest       => "${targets_path}/webperf_arclamp_${::site}.yaml",
        class_name => 'profile::webperf::arclamp',
        port       => 80,
    }

    $thanos_jobs = [
      {
        'job_name'        => 'thanos-query',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/thanos_query_*.yaml" ]}
        ],
      },
      {
        'job_name'        => 'thanos-query-frontend',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/thanos_query-frontend_*.yaml" ]}
        ],
      },
      {
        'job_name'        => 'thanos-sidecar',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/thanos_sidecar_*.yaml" ]}
        ],
      },
      {
        'job_name'        => 'thanos-store',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/thanos_store_*.yaml" ]}
        ],
      },
      {
        'job_name'        => 'thanos-compact',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/thanos_compact_*.yaml" ]}
        ],
      },
      {
        'job_name'        => 'thanos-rule',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/thanos_rule_*.yaml" ]}
        ],
      },
    ]

    prometheus::class_config{ "thanos_query_${::site}":
        dest       => "${targets_path}/thanos_query_${::site}.yaml",
        class_name => 'thanos::query',
        port       => 10902,
    }

    prometheus::class_config{ "thanos_query-frontend_${::site}":
        dest       => "${targets_path}/thanos_query-frontend_${::site}.yaml",
        class_name => 'thanos::query_frontend',
        port       => 16902,
    }

    prometheus::resource_config{ "thanos_sidecar_${::site}":
        dest           => "${targets_path}/thanos_sidecar_${::site}.yaml",
        define_name    => 'thanos::sidecar',
        port_parameter => 'http_port',
    }

    prometheus::class_config{ "thanos_store_${::site}":
        dest       => "${targets_path}/thanos_store_${::site}.yaml",
        class_name => 'thanos::store',
        port       => 11902,
    }

    prometheus::class_config{ "thanos_compact_${::site}":
        dest       => "${targets_path}/thanos_compact_${::site}.yaml",
        class_name => 'thanos::compact::prometheus',
        port       => 12902,
    }

    prometheus::class_config{ "thanos_rule_${::site}":
        dest       => "${targets_path}/thanos_rule_${::site}.yaml",
        class_name => 'thanos::rule::prometheus',
        port       => 17902,
    }

    # Jobs for Netbox script-based exported metrics
    # 2m of scrape interval as they're high level data (number of devices, etc),
    # which don't change at a high rate, but it's also not recommended to have
    # an interval > 2m (see related CR)
    $netbox_jobs = [
        # device statistics
        {
            'job_name'     => 'netbox_device_statistics',
            'metrics_path' => '/getstats.GetDeviceStats',
            'scheme'          => 'https',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/netbox_scripts_exporter_${::site}.yaml"] },
            ],
            'scrape_interval'    => '2m',
        }
    ]
    prometheus::class_config { "netbox_scripts_exporter_${::site}":
        dest           => "${targets_path}/netbox_scripts_exporter_${::site}.yaml",
        hostnames_only => false,
        class_name     => 'role::netbox::frontend',
        port           => 8443
    }

    # Jobs for Netbox django health metrics - T243928
    $netbox_django_jobs = [
        {
            'job_name'     => 'netbox_django',
            'scheme'          => 'https',
            'file_sd_configs' => [
                { 'files' => [ "${targets_path}/netbox_django_*.yaml"] },
            ],
            'tls_config'        => {
                'server_name'   => 'netbox.wikimedia.org',
            },
        }
    ]
    prometheus::class_config { "netbox_django_${::site}":
        dest       => "${targets_path}/netbox_django_${::site}.yaml",
        class_name => 'role::netbox::frontend',
        port       => 443
    }

    $wikidough_jobs = [
      {
        'job_name'        => 'wikidough',
        'metrics_path'    => '/metrics',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/wikidough_*.yaml" ]}
        ],
        'basic_auth'      => {
            'username' => anyuser,
            'password' => $wikidough_password,
        },
      },
    ]

    prometheus::class_config { "wikidough_${::site}":
        dest       => "${targets_path}/wikidough_${::site}.yaml",
        class_name => 'profile::wikidough',
        port       => 8083,
    }

    # Job definition for chartmuseum
    $chartmuseum_jobs = [
      {
        'job_name'        => 'chartmuseum',
        'scheme'          => 'https',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/chartmuseum_*.yaml"] },
        ],
        'tls_config'        => {
            'server_name'   => 'helm-charts.wikimedia.org',
        },
      },
    ]
    prometheus::class_config{ "chartmuseum_${::site}":
        dest       => "${targets_path}/chartmuseum_${::site}.yaml",
        class_name => 'chartmuseum',
        port       => 443,
        labels     => {}
    }

    # Job definition for minio (mediabackup::storage)
    $minio_jobs = [
        {
        'job_name'        => 'minio',
        'scheme'          => 'https',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/minio_*.yaml"] },
        ],
        'metrics_path'    => '/minio/v2/metrics/cluster',  # there are also per node stats
      },
    ]
    prometheus::class_config{ "minio_${::site}":
        dest       => "${targets_path}/minio_${::site}.yaml",
        class_name => 'profile::mediabackup::storage',
        port       => 9000,
    }

    # Job definition for dragonfly supernode and clients (dfdaemon)
    $dragonfly_jobs = [
      {
        'job_name'        => 'dragonfly_supernode',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/dragonfly_supernode_*.yaml"] },
        ],
      },
      {
        'job_name'        => 'dragonfly_dfdaemon',
        'scheme'          => 'https',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/dragonfly_dfdaemon_*.yaml"] },
        ],
      },
    ]
    prometheus::class_config{ "dragonfly_supernode_${::site}":
        dest       => "${targets_path}/dragonfly_supernode_${::site}.yaml",
        class_name => 'dragonfly::supernode',
        port       => 8002,
    }
    prometheus::class_config{ "dragonfly_dfdaemon_${::site}":
        dest       => "${targets_path}/dragonfly_dfdaemon_${::site}.yaml",
        class_name => 'dragonfly::dfdaemon',
        port       => 65001,
    }

    # Job definition for gitlab T275170
    $gitlab_jobs = [
      {
        'job_name'        => 'nginx',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/nginx_*.yaml"] },
        ]
      },
      # dedicated redis_gitlab job following current pattern (see redis_sessions, redis_misc)
      {
        'job_name'        => 'redis_gitlab',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/redis_gitlab_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'workhorse',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/workhorse_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'rails',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/rails_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'sidekiq',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/sidekiq_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'gitlab',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/gitlab_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'gitaly',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/gitaly_*.yaml"] },
        ]
      },
    ]
    prometheus::class_config{ "nginx_${::site}":
        dest       => "${targets_path}/nginx_${::site}.yaml",
        class_name => 'profile::gitlab',
        port       => 8060
    }
    prometheus::class_config{ "redis_gitlab_${::site}":
        dest       => "${targets_path}/redis_gitlab_${::site}.yaml",
        class_name => 'profile::gitlab',
        port       => 9121
    }
    # existing postgresql job is reused (see $postgresql_jobs)
    prometheus::class_config{ "postgresql_gitlab_${::site}":
        dest       => "${targets_path}/postgresql_gitlab_${::site}.yaml",
        class_name => 'profile::gitlab',
        port       => 9187
    }
    prometheus::class_config{ "workhorse_${::site}":
        dest       => "${targets_path}/workhorse_${::site}.yaml",
        class_name => 'profile::gitlab',
        port       => 9229
    }
    prometheus::class_config{ "rails_${::site}":
        dest       => "${targets_path}/rails_${::site}.yaml",
        class_name => 'profile::gitlab',
        port       => 8083
    }
    prometheus::class_config{ "sidekiq_${::site}":
        dest       => "${targets_path}/sidekiq_${::site}.yaml",
        class_name => 'profile::gitlab',
        port       => 8082
    }
    prometheus::class_config{ "gitlab_${::site}":
        dest       => "${targets_path}/gitlab_${::site}.yaml",
        class_name => 'profile::gitlab',
        port       => 9168
    }
    prometheus::class_config{ "gitaly_${::site}":
        dest       => "${targets_path}/gitaly_${::site}.yaml",
        class_name => 'profile::gitlab',
        port       => 9236
    }

    # Job definition for gitlab-runner monitoring T295481
    $gitlab_runner_jobs = [
      {
        'job_name'        => 'gitlab_runner',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/gitlab_runner_*.yaml"] },
        ]
      },
    ]
    prometheus::class_config{ "gitlab_runner_${::site}":
        dest       => "${targets_path}/gitlab_runner_${::site}.yaml",
        class_name => 'profile::gitlab::runner',
        port       => 9252
    }

    $cfssl_jobs = [
      {
        'job_name'        => 'cfssl',
        'scheme'          => 'http',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/pki_*.yaml"] },
        ],
      },
    ]
    prometheus::class_config{ "pki_${::site}":
        dest       => "${targets_path}/pki_${::site}.yaml",
        port       => 80,
        class_name => 'profile::pki::multirootca',
        labels     => {
            'cluster' => 'pki',
            'app'     => 'cfssl',
        },
    }

    $max_block_duration = ($enable_thanos_upload and $disable_compaction) ? {
        true    => '2h',
        default => '24h',
    }

    prometheus::server { 'ops':
        listen_address                 => "127.0.0.1:${port}",
        storage_retention              => $storage_retention,
        storage_retention_size         => $storage_retention_size,
        max_chunks_to_persist          => $max_chunks_to_persist,
        memory_chunks                  => $memory_chunks,
        min_block_duration             => '2h',
        max_block_duration             => $max_block_duration,
        alertmanagers                  => $alertmanagers.map |$a| { "${a}:9093" },
        scrape_configs_extra           => [
            $mysql_jobs, $varnish_jobs, $trafficserver_jobs, $purged_jobs, $memcached_jobs,
            $apache_jobs, $etcd_jobs, $etcdmirror_jobs, $kubetcd_jobs, $ml_etcd_jobs, $mcrouter_jobs, $pdu_jobs,
            $pybal_jobs, $blackbox_jobs, $probes_jobs, $jmx_exporter_jobs,
            $redis_jobs, $mtail_jobs, $ldap_jobs, $pdns_rec_jobs,
            $etherpad_jobs, $elasticsearch_jobs, $wmf_elasticsearch_jobs,
            $blazegraph_jobs, $nutcracker_jobs, $postgresql_jobs, $ipsec_jobs,
            $kafka_burrow_jobs, $logstash_jobs, $haproxy_jobs, $statsd_exporter_jobs,
            $mjolnir_jobs, $rsyslog_jobs, $php_jobs, $icinga_jobs, $docker_registry_jobs,
            $gerrit_jobs, $routinator_jobs, $varnishkafka_jobs, $bird_jobs, $ncredir_jobs,
            $cloud_dev_pdns_jobs, $cloud_dev_pdns_rec_jobs, $bacula_jobs, $poolcounter_exporter_jobs,
            $atlas_exporter_jobs, $exported_blackbox_jobs, $cadvisor_jobs,
            $envoy_jobs, $webperf_jobs, $squid_jobs, $nic_saturation_exporter_jobs, $thanos_jobs, $netbox_jobs,
            $wikidough_jobs, $chartmuseum_jobs, $es_exporter_jobs, $alertmanager_jobs, $pushgateway_jobs,
            $udpmxircecho_jobs, $minio_jobs, $dragonfly_jobs, $gitlab_jobs, $cfssl_jobs, $cache_haproxy_tls_jobs,
            $cache_envoy_jobs, $mini_textfile_jobs, $gitlab_runner_jobs,
            $netbox_django_jobs, $ipmi_jobs, $ganeti_jobs
        ].flatten,
        global_config_extra            => $config_extra,
        alerting_relabel_configs_extra => $alerting_relabel_configs_extra,
    }

    prometheus::web { 'ops':
        proxy_pass => "http://localhost:${port}/ops",
        homepage   => true,
    }

    profile::thanos::sidecar { 'ops':
        prometheus_port     => $port,
        prometheus_instance => 'ops',
        enable_upload       => $enable_thanos_upload,
        min_time            => $thanos_min_time,
    }

    file { '/srv/prometheus/ops/gerrit.token':
        ensure  => present,
        content => $gerrit_client_token,
        mode    => '0400',
        owner   => 'prometheus',
        group   => 'prometheus',
        backup  => false,
    }

    ferm::service { 'prometheus-web':
        proto  => 'tcp',
        port   => '80',
        srange => '$DOMAIN_NETWORKS',
    }

    $gerrit_targets = {
      'targets' => ['gerrit.wikimedia.org:443'],
      'labels'  => {'cluster' => 'misc', 'site' => 'eqiad'},
    }

    file {
        default:
            backup => false,
            owner  => 'root',
            group  => 'root',
            mode   => '0444';
        "${targets_path}/node_site_${::site}.yaml":
            content => template('profile/prometheus/node_site.yaml.erb');
        # Ping and SSH probes for all bastions from all machines running
        # prometheus::ops
        "${targets_path}/blackbox_icmp_bastions.yaml":
            content => to_yaml([{'targets' => $bastion_hosts}]);
        "${targets_path}/blackbox_ssh_bastions.yaml":
            content => to_yaml([{
                'targets' => regsubst($bastion_hosts, '(.*)', '[\0]:22')
            }]);
        "${targets_path}/gerrit.yaml":
            content => to_yaml([$gerrit_targets]);
        # Generic HTTPS probes for a static list of urls defined in hiera
        "${targets_path}/blackbox_pingthing_http_check_urls.yaml":
            content => to_yaml([{'targets' => $blackbox_pingthing_http_check_urls}]);
        # Same, but needing outproxy proxy support
        "${targets_path}/blackbox_pingthing_proxied_urls.yaml":
            content => to_yaml([{'targets' => $blackbox_pingthing_proxied_urls}]);
    }

    prometheus::rule { 'rules_ops.yml':
        instance => 'ops',
        source   => 'puppet:///modules/profile/prometheus/rules_ops.yml',
    }

    prometheus::rule { 'alerts_ops.yml':
        instance => 'ops',
        source   => 'puppet:///modules/role/prometheus/alerts_ops.yml',
    }

    prometheus::cluster_config{ 'text_frontend':
        dest    => "${targets_path}/varnish-text_${::site}_frontend.yaml",
        cluster => 'cache_text',
        port    => 9331,
        labels  => {
          'layer' => 'frontend',
        },
    }

    prometheus::cluster_config{ 'upload_frontend':
        dest    => "${targets_path}/varnish-upload_${::site}_frontend.yaml",
        cluster => 'cache_upload',
        port    => 9331,
        labels  => {
          'layer' => 'frontend',
        },
    }

    prometheus::class_config { 'ipmi':
        dest       => "${targets_path}/ipmi_${::site}.yaml",
        class_name => 'prometheus::ipmi_exporter',
        port       => 9290,
    }

    if $::site in ['eqiad', 'codfw'] {
        sysctl::parameters { 'prometheus_inotify_T246860':   # https://phabricator.wikimedia.org/T246860
            values => {
                'fs.inotify.max_user_watches'   => 32768,
                'fs.inotify.max_user_instances' => 512
            }
        }
    }
}
