# SPDX-License-Identifier: Apache-2.0
#
# This class configures elasticsearch
#
# == Parameters:
#
# For documentation of parameters, see the elasticsearch profile.
#
# [*expose_http*]
#   For historical reason we expose HTTP endpoints. For new clusters, we want
#   to disable that, and cleanup the old ones. For transition, let's make this
#   configureable.
class profile::elasticsearch::cirrus(
    String $cluster = lookup('cluster'),
    String $ferm_srange = lookup('profile::elasticsearch::cirrus::ferm_srange'),
    String $ferm_ro_srange = lookup('profile::elasticsearch::cirrus::ferm_ro_srange', {default_value => ''}),
    Boolean $expose_http = lookup('profile::elasticsearch::cirrus::expose_http'),
    String $storage_device = lookup('profile::elasticsearch::cirrus::storage_device'),
    Boolean $enable_remote_search = lookup('profile::elasticsearch::cirrus::enable_remote_search'),
    Profile::Pki::Provider $ssl_provider = lookup('profile::elasticsearch::cirrus::ssl_provider'),
) {
    include ::profile::elasticsearch

    # syslog logstash transport type depends on this. See T225125.
    include ::profile::rsyslog::udp_json_logback_compat

    # nginx, which terminates tls for elasticsearch, needs `/etc/ssl/dhparam.pem` to be in place in order to function.
    class { '::sslcert::dhparam': }

    package {'wmf-elasticsearch-search-plugins':
        ensure  => present,
        require => [Class['Java'], Package['elasticsearch-oss']],
    }

    # Since the elasticsearch service is dynamically named after the cluster
    # name, and because there can be multiple elasticsearch services on the
    # same node we need to use collectors.
    Package['wmf-elasticsearch-search-plugins'] -> Service <| tag == 'elasticsearch_services' |>

    # Alternatively we could pass these again?
    # certificate_name and tls_port aren't even
    # elasticsearch::instance params,

    $::profile::elasticsearch::filtered_instances.each |$instance_title, $instance_params| {
        $cluster_name = $instance_params['cluster_name']
        $http_port = $instance_params['http_port']
        $tls_port = $instance_params['tls_port']
        $tls_ro_port = $instance_params['tls_ro_port']

        if $expose_http {
            ferm::service { "elastic-http-${http_port}":
                proto   => 'tcp',
                port    => $http_port,
                notrack => true,
                srange  => $ferm_srange,
            }
        }

        ferm::service { "elastic-https-${tls_port}":
            proto  => 'tcp',
            port   => $tls_port,
            srange => $ferm_srange,
        }

        if $ssl_provider == 'acme_chief' {
            $proxy_cert_params = {
                acme_chief        => true,
                acme_certname     => $cluster,
                server_name       => $instance_params['certificate_name'],
            }
        }

        if $ssl_provider == 'cfssl' {
            $cfssl_paths = profile::pki::get_cert('discovery', $facts['networking']['fqdn'], {
                hosts => [$instance_params['certificate_name'], "search.svc.${::site}.wmnet"],
            })

            $proxy_cert_params = {
                'cfssl_paths'  => $cfssl_paths,
                server_aliases => [$instance_params['certificate_name'],"search.svc.${::site}.wmnet"],
            }
        }

        $proxy_params = merge($proxy_cert_params, {
            upstream_port => $http_port,
            tls_port      => $tls_port,
            enable_http2  => false,
        })

        elasticsearch::tlsproxy { $cluster_name:
            * => $proxy_params,
        }
        if $tls_ro_port {
            if empty($ferm_ro_srange) {
                fail('Read only port specified without a read only srange')
            }

            ferm::service { "elastic-ro-https-${tls_ro_port}":
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

        elasticsearch::log::hot_threads_cluster { $cluster_name:
            http_port => $http_port,
        }

        # Also limit these checks to only the master nodes to reduce duplication
        # of these checks on all nodes until we find a better way to run these checks
        # only on icinga nodes
        if $facts['fqdn'] in $instance_params['unicast_hosts'] {
            elasticsearch::cross_cluster_settings { $instance_title:
                http_port            => $http_port,
                settings             => $::profile::elasticsearch::configured_instances,
                enable_remote_search => $enable_remote_search,
            }

            icinga::monitor::elasticsearch::cirrus_settings_check { $instance_title:
                port                 => $http_port,
                settings             => $::profile::elasticsearch::configured_instances,
                enable_remote_search => $enable_remote_search,
            }
            # T357146 monitor Elastic snapshot repository
            # All clusters use the same repo, which enables cross-cluster snapshot restores.
            prometheus::blackbox::check::http { "${facts['fqdn']}_${instance_title}_snapshot":
                server_name    => $facts['fqdn'],
                team           => 'data-platform-sre',
                severity       => 'task',
                path           => '/_snapshot/elastic_snaps',
                ip_families    => ['ip4','ip6'],
                status_matches => [200],
                force_tls      => true,
            }
        }
    }

    $read_ahead_kb = 16
    udev::rule { 'elasticsearch-readahead':
        content => "SUBSYSTEM==\"block\", KERNEL==\"${storage_device}\", ACTION==\"add|change\", ATTR{bdi/read_ahead_kb}=\"${read_ahead_kb}\"",
    }

    ## BEGIN Temporary mitigation put in place for T264053
    # Source code lives here: https://phabricator.wikimedia.org/P5883
    package {'elasticsearch-madvise':
        ensure => present,
    }

    # Add elastic bin to root's PATH
    file_line { 'elastic_bin_bashrc':
      ensure => present,
      path   => '/root/.bashrc',
      line   => "PATH=\${PATH}:/usr/share/elasticsearch/bin  # Managed by puppet",
    }

    # Wrapper script to run elasticsearch-madvise-random once per elasticsearch process, passing PID
    file { '/usr/local/bin/elasticsearch-disable-readahead.sh':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/elasticsearch/cirrus/elasticsearch-disable-readahead.sh',
    }

    # Run the wrapper every 30 mins
    systemd::timer::job { 'elasticsearch-disable-readahead':
        description => 'Disables readahead on all open files every 30 minutes to alleviate Cirrussearch / elasticsearch IO load spikes',
        command     => '/usr/local/bin/elasticsearch-disable-readahead.sh',
        user        => 'root',
        interval    => [{'start' => 'OnUnitActiveSec', 'interval' => '30min'}, {'start' => 'OnBootSec', 'interval' => '1min'}],
    }
    ## END   Temporary mitigation put in place for T264053

    # Install prometheus data collection
    $::profile::elasticsearch::filtered_instances.reduce(9108) |$prometheus_port, $kv_pair| {
        $instance_params = $kv_pair[1]
        $http_port = $instance_params['http_port']
        $indices_to_monitor = $instance_params['indices_to_monitor'] ? {
            undef   => [],
            default => $instance_params['indices_to_monitor']
        }

        profile::prometheus::elasticsearch_exporter { "${::hostname}:${http_port}":
            prometheus_port    => $prometheus_port,
            elasticsearch_port => $http_port,
        }
        profile::prometheus::wmf_elasticsearch_exporter { "${::hostname}:${http_port}":
            prometheus_port    => $prometheus_port + 1,
            elasticsearch_port => $http_port,
            indices_to_monitor => $indices_to_monitor,
        }
        $prometheus_port + 2
    }
    motd::script { 'cluster_memberships':
      ensure   => present,
      priority => 96,
      source   => 'puppet:///modules/elasticsearch/elastic.motd',
    }
}
