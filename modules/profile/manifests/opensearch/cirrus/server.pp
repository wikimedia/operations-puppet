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
    String $ferm_ro_srange = lookup('profile::opensearch::cirrus::ferm_ro_srange', { default_value => '' }),
    Boolean $expose_http = lookup('profile::opensearch::cirrus::expose_http'),
    String $storage_device = lookup('profile::opensearch::cirrus::storage_device'),
    Boolean $enable_remote_search = lookup('profile::opensearch::cirrus::enable_remote_search'),
    Profile::Pki::Provider $ssl_provider = lookup('profile::opensearch::cirrus::ssl_provider'),
    Stdlib::AbsolutePath $base_data_dir = lookup('profile::opensearch::base_data_dir'),
    Array $certificate_domains = lookup('profile::opensearch::cirrus::certificate_domains'),
    Boolean $enable_performance_cpu_governor = lookup('profile::opensearch::cirrus::enable_performance_cpu_governor', { 'default_value' => false }),
    Opensearch::SemVer  $version = lookup('profile::opensearch::version', { 'default_value' => '2.19.5' }),
    Boolean $ship_server_json_logs = lookup('profile::opensearch::cirrus::server::ship_server_json_logs', { 'default_value' => false }),
) {

    if $enable_performance_cpu_governor {
        # enable CPU performance governor; see T386860
        class { 'cpufrequtils': }
    }

    # Also brings in ::profile::opensearch::server
    include ::profile::opensearch::monitoring::base_checks

    # Ship the on-disk JSON server logs to the logging pipeline (T324335).
    # The logs are single-line ECS events, produced by EcsLayout (T401933).
    # we can't use an ensure => absent as of the writing, because
    # modules/rsyslog/manifests/input/file.pp#29 executes regardless of
    # whether `Rsyslog::Conf['imfile']`is defined or not.

    if $ship_server_json_logs {
        rsyslog::input::file { 'opensearch-server-json':
            ensure => present,
            path   => '/var/log/opensearch/*_server.json',
        }
    }

    # nginx, which terminates tls for elasticsearch, needs `/etc/ssl/dhparam.pem` to be in place in order to function.
    class { '::sslcert::dhparam': }


    # Recycled from modules/profile/manifests/opensearch/server.pp

    # Starting with Bookworm the Debian installer defaults to using the signed-by
    # notation in apt-setup, also apply the same for the puppetised Wikimedia
    # repository.
    # The signed-by notation allows to specify which repository key is used
    # for which repository (previously they applied to all repos)
    # https://wiki.debian.org/DebianRepository/UseThirdParty
    if debian::codename::ge('bookworm') {
        $wikimedia_apt_keyfile = 'puppet:///modules/install_server/autoinstall/keyring/wikimedia-archive-keyring.gpg'
    } else {
        $wikimedia_apt_keyfile = undef
    }

    # FIXME: Make more DRY

    $major_version = split($version, '[.]')[0]

    if Integer($major_version) >= 2 {
        $apt_component = "component/opensearch${major_version}"
    } else {
        $apt_component = 'component/opensearch13'
    }

    apt::repository { 'wikimedia-opensearch-plugins':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${facts['os']['distro']['codename']}-wikimedia",
        components => $apt_component,
        keyfile    => $wikimedia_apt_keyfile,
    }

    package { 'wmf-opensearch-search-plugins':
        ensure  => present,
        require => [Class['Java'], Package['opensearch']],
    }

    # ecs-logging-java jars for the EcsLayout server logs (T324335).
    # The jars only join the classpath when an instance is restarted.
    package { 'opensearch-ecs-logging':
        ensure  => present,
        require => Package['opensearch'],
    }

    # Since the opensearch service is dynamically named after the cluster
    # name, and because there can be multiple opensearch services on the
    # same node we need to use collectors.
    Package['wmf-opensearch-search-plugins'] -> Service <| tag == 'opensearch_services' |>
    Package['opensearch-ecs-logging'] -> Service <| tag == 'opensearch_services' |>

    $::profile::opensearch::server::filtered_instances.each |$instance_title, $instance_params| {
        $cluster_name = $instance_params['cluster_name']
        $http_port = $instance_params['http_port']
        $tls_port = $instance_params['tls_port']
        opensearch::log::hot_threads_cluster { $cluster_name:
            http_port => $http_port,
        }

        # Use the opensearch::master_eligible defined type so we can target
        # masters-eligible with cumin.

        if $facts['networking']['fqdn'] in $instance_params['unicast_hosts'] {
            opensearch::master_eligible { $instance_title:
                cluster_name       => $cluster_name,
                short_cluster_name => $instance_params['short_cluster_name'],
            }

            # Limit these checks to only the master nodes to reduce duplication

            opensearch::cross_cluster_settings { $instance_title:
                settings             => $::profile::opensearch::server::configured_instances,
                enable_remote_search => $enable_remote_search,
            }
        }
    }

    $read_ahead_kb = 16
    udev::rule { 'opensearch-readahead':
        content => "SUBSYSTEM==\"block\", KERNEL==\"${storage_device}\", ACTION==\"add|change\", ATTR{bdi/read_ahead_kb}=\"${read_ahead_kb}\"",
    }

    sysctl::parameters { 'opensearch':
      values             => {
          'vm.max_map_count' => 1048576,
      },
      no_priority_prefix => true,
    }

    # BEGIN Temporary mitigation put in place for T264053
    # Source code lives here: https://gitlab.wikimedia.org/repos/search-platform/opensearch-madvise
    package {'opensearch-madvise':
        ensure => present,
    }

    # Add opensearch bin to root's PATH
    file_line { 'opensearch_bin_bashrc':
      ensure => present,
      path   => '/root/.bashrc',
      line   => "PATH=\${PATH}:/usr/share/opensearch/bin  # Managed by puppet",
    }

    # Wrapper script to run opensearch-madvise-random once per opensearch process, passing PID
    file { '/usr/local/bin/opensearch-disable-readahead.sh':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/opensearch/cirrus/opensearch-disable-readahead.sh',
    }

    systemd::timer::job { 'opensearch-disable-readahead':
        ensure      => absent,
        description => 'Disables readahead on all open files every 30 minutes to alleviate Cirrussearch / opensearch IO load spikes',
        command     => '/usr/local/bin/opensearch-disable-readahead.sh',
        user        => 'root',
        interval    => [{'start' => 'OnUnitActiveSec', 'interval' => '30min'}, {'start' => 'OnBootSec', 'interval' => '1min'}],
    }

    # Run the wrapper every 30 mins for each installed cluster
    $::profile::opensearch::server::filtered_instances.each |$instance_title, $instance_params| {
        $cluster_name = $instance_params['cluster_name']

        systemd::timer::job { "opensearch-disable-readahead-${cluster_name}":
            description => 'Disables readahead on all open files every 30 minutes to alleviate Cirrussearch / opensearch IO load spikes',
            command     => "/usr/local/bin/opensearch-disable-readahead.sh ${cluster_name} ${base_data_dir}",
            user        => 'root',
            interval    => [{'start' => 'OnUnitActiveSec', 'interval' => '30min'}, {'start' => 'OnBootSec', 'interval' => '1min'}],
        }
    }

    # END   Temporary mitigation put in place for T264053

    # Install custom prometheus data collection. Standard data collection is
    # configured from profile::opensearch::server.
    $::profile::opensearch::server::filtered_instances.reduce(9120) |$prometheus_port, $kv_pair| {
        $instance_params = $kv_pair[1]
        $http_port = $instance_params['http_port']
        $indices_to_monitor = $instance_params['indices_to_monitor'] ? {
            undef   => [],
            default => $instance_params['indices_to_monitor']
        }

        profile::prometheus::wmf_elasticsearch_exporter { "${facts['networking']['hostname']}:${http_port}":
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

    # symlink elasticsearch to opensearch, so we can run our rolling-operation
    # cookbook without patching Spicerack
    # (ref https://gerrit.wikimedia.org/r/plugins/gitiles/operations/software/spicerack/+/refs/heads
    # /master/spicerack/elasticsearch_cluster.py#111
    file { '/etc/elasticsearch':
        ensure  => link,
        target  => '/etc/opensearch',
        require => File['/etc/opensearch/instances'],
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
        if $ssl_provider == 'acme_chief' {
            $proxy_cert_params = {
                acme_chief        => true,
                acme_certname     => $cluster,
                server_name       => $instance_params['certificate_name'],
            }
        }

        if $ssl_provider == 'cfssl' {
            $cfssl_paths = profile::pki::get_cert('discovery2026', $facts['networking']['fqdn'], {
                hosts => $certificate_domains,
            })

            $proxy_cert_params = {
                'cfssl_paths'  => $cfssl_paths,
                server_aliases => $certificate_domains,
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
