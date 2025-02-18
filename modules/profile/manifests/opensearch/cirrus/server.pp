# SPDX-License-Identifier: Apache-2.0
#
# This class configures OpenSearch for serving CirrusSearch
#
# == Parameters:
#
# For documentation of parameters, see the opensearch profile.
#
class profile::opensearch::cirrus::server(
    String $cluster = lookup('cluster'),
    String $ferm_srange = lookup('profile::opensearch::cirrus::ferm_srange'),
    String $ferm_ro_srange = lookup('profile::opensearch::cirrus::ferm_ro_srange', {default_value => ''}),
    Boolean $expose_http = lookup('profile::opensearch::cirrus::expose_http'),
    String $storage_device = lookup('profile::opensearch::cirrus::storage_device'),
    Boolean $enable_remote_search = lookup('profile::opensearch::cirrus::enable_remote_search'),
    Profile::Pki::Provider $ssl_provider = lookup('profile::opensearch::cirrus::ssl_provider'),
) {
    # Also brings in ::profile::opensearch::server
    include ::profile::opensearch::monitoring::base_checks

    # syslog logstash transport type depends on this. See T225125.
    # TODO: Check if still necessary w/opensearch
    include ::profile::rsyslog::udp_json_logback_compat

    $apt_component = 'opensearch13'
    apt::repository { 'wikimedia-opensearch-plugins':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => "component/${apt_component}",
    }

    package {'wmf-opensearch-search-plugins':
        ensure  => present,
        require => [Class['Java'], Package['opensearch']],
    }

    # Since the opensearch service is dynamically named after the cluster
    # name, and because there can be multiple opensearch services on the
    # same node we need to use collectors.
    Package['wmf-opensearch-search-plugins'] -> Service <| tag == 'opensearch_services' |>

    $::profile::opensearch::server::filtered_instances.each |$instance_title, $instance_params| {
        $cluster_name = $instance_params['cluster_name']
        $http_port = $instance_params['http_port']

        opensearch::log::hot_threads_cluster { $cluster_name:
            http_port => $http_port,
        }

        # Also limit these checks to only the master nodes to reduce duplication
        # of these checks on all nodes until we find a better way to run these checks
        # only on icinga nodes
        if $facts['fqdn'] in $instance_params['unicast_hosts'] {
            opensearch::cross_cluster_settings { $instance_title:
                settings             => $::profile::opensearch::server::configured_instances,
                enable_remote_search => $enable_remote_search,
            }

            # T357146 monitor snapshot repository
            # All clusters use the same repo, which enables cross-cluster snapshot restores.
            prometheus::blackbox::check::http { "${facts['fqdn']}_${instance_title}_snapshot":
                server_name    => $facts['fqdn'],
                team           => 'data-platform-sre',
                severity       => 'task',
                path           => '/_snapshot/elastic_snaps',
                port           => $http_port,
                ip_families    => ['ip4','ip6'],
                status_matches => [200],
                force_tls      => true,
            }
        }
    }

    $read_ahead_kb = 16
    udev::rule { 'opensearch-readahead':
        content => "SUBSYSTEM==\"block\", KERNEL==\"${storage_device}\", ACTION==\"add|change\", ATTR{bdi/read_ahead_kb}=\"${read_ahead_kb}\"",
    }

    ## BEGIN Temporary mitigation put in place for T264053
    # Source code lives here: https://phabricator.wikimedia.org/P5883
    ## madvise-related code disabled while we decide if we still need it (T386281).
    # package {'opensearch-madvise':
    #     ensure => present,
    # }
    #
    # # Add opensearch bin to root's PATH
    # file_line { 'opensearch_bin_bashrc':
    #   ensure => present,
    #   path   => '/root/.bashrc',
    #   line   => "PATH=\${PATH}:/usr/share/opensearch/bin  # Managed by puppet",
    # }
    #
    # # Wrapper script to run opensearch-madvise-random once per opensearch process, passing PID
    # file { '/usr/local/bin/opensearch-disable-readahead.sh':
    #     ensure => file,
    #     owner  => 'root',
    #     group  => 'root',
    #     mode   => '0555',
    #     source => 'puppet:///modules/profile/opensearch/cirrus/opensearch-disable-readahead.sh',
    # }
    #
    # # Run the wrapper every 30 mins
    # systemd::timer::job { 'opensearch-disable-readahead':
    #     description => 'Disables readahead on all open files every 30 minutes to alleviate Cirrussearch / opensearch IO load spikes',
    #     command     => '/usr/local/bin/opensearch-disable-readahead.sh',
    #     user        => 'root',
    #     interval    => [{'start' => 'OnUnitActiveSec', 'interval' => '30min'}, {'start' => 'OnBootSec', 'interval' => '1min'}],
    # }
    ## END   Temporary mitigation put in place for T264053

    # Install custom prometheus data collection. Standard data collection is
    # configured from profile::opensearch::server.
    $::profile::opensearch::server::filtered_instances.reduce(9120) |$prometheus_port, $kv_pair| {
        $instance_params = $kv_pair[1]
        $http_port = $instance_params['http_port']
        $indices_to_monitor = $instance_params['indices_to_monitor'] ? {
            undef   => [],
            default => $instance_params['indices_to_monitor']
        }

        profile::prometheus::wmf_elasticsearch_exporter { "${::hostname}:${http_port}":
            prometheus_port    => $prometheus_port,
            elasticsearch_port => $http_port,
            indices_to_monitor => $indices_to_monitor,
        }
        $prometheus_port + 1
    }

    motd::script { 'cluster_memberships':
      ensure   => present,
      priority => 96,
      source   => 'puppet:///modules/opensearch/opensearch.motd',
    }

    # TLS configuration
    # For legacy reasons this reuses elasticsearch::tlsproxy until we can
    # enable the opensearch security plugin for native tls.
    $::profile::opensearch::server::filtered_instances.each |$instance_title, $instance_params| {
        $cluster_name = $instance_params['cluster_name']
        $http_port = $instance_params['http_port']
        $tls_port = $instance_params['tls_port']
        $tls_ro_port = $instance_params['tls_ro_port']

        if $expose_http {
            ferm::service { "opensearch-http-${http_port}":
                proto   => 'tcp',
                port    => $http_port,
                notrack => true,
                srange  => $ferm_srange,
            }
        }

        ferm::service { "opensearch-https-${tls_port}":
            proto  => 'tcp',
            port   => $tls_port,
            srange => $ferm_srange,
        }
        $proxy_params = $ssl_provider ? {
            'acme_chief' => {
                acme_chief        => true,
                acme_certname     => $cluster,
                server_name       => $instance_params['certificate_name'],
            },

            'cfssl' => {
                cfssl_paths    => profile::pki::get_cert('discovery', $facts['networking']['fqdn'], {
                    hosts => [
                        $instance_params['certificate_name'],
                        "search.svc.${::site}.wmnet"
                    ],
                }),
                server_aliases => [
                    $instance_params['certificate_name'],
                    "search.svc.${::site}.wmnet"
                ],
            }
        }

        elasticsearch::tlsproxy { $cluster_name:
            upstream_port => $http_port,
            tls_port      => $tls_port,
            enable_http2  => false,
            *             => $proxy_params,
        }

        if $tls_ro_port {
            if empty($ferm_ro_srange) {
                fail('Read only port specified without a read only srange')
            }

            ferm::service { "opensearch-ro-https-${tls_ro_port}":
                proto  => 'tcp',
                port   => $tls_ro_port,
                srange => $ferm_ro_srange,
            }

            elasticsearch::tlsproxy { "${cluster_name}-ro":
                * => merge($proxy_params, {
                    tls_port  => $tls_ro_port,
                    read_only => true,
                })
            }
        }
    }
}
