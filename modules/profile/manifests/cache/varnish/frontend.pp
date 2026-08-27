# SPDX-License-Identifier: Apache-2.0
# @summary profile to configure frontend varnish cache
# @param cache_nodes list of all cache nodes
# @param cache_cluster name of cache cluster e.g. upload or text
# @param conftool_prefix the prefix to use for conftool
# @param fe_vcl_config A hash if vcl config
# @param runtime_params A hash of runtime parameters
# @param fe_cache_be_opts hash of backend configs
# @param backends_in_etcd indicate if backends are in etcd
# @param fe_extra_vcl list of extra VCLs
# @param req_handling hash of domains request handling config
# @param alternate_domains List of domains handled by misc
# @param packages_component The package component to use for apt
# @param fe_transient_gb Amount of Transient=malloc to configure in GB
# @param separate_vcl list of addtional VCLs
# @param has_lvs Indicate of cache is behind LVS
# @param single_backend Feature flag to use only the host-local ats-be (drmrs only)
# @param listen_uds list of uds for varnish
# @param uds_owner The owner of the uds sockets
# @param uds_group The group of the uds sockets
# @param uds_mode The mode of the uds sockets
# @param privileged_uds Socket used by purged
# @param use_etcd_req_filters use confd dynamically generated rules
# @param use_private_repo use the private repository (such as for browser detection)
# @param do_esitest temporary for testing ESI
# @param fe_jemalloc_conf jemalloc configuration
# @param thread_pool_max Maximum threads per pool
# @param vsl_size Size of the space for VSL records (default 160M)
# @param fe_mem_gb_reserved Frontend memory cache size will be set to total host memory minus this many GB (def 170)
# @param check_min_fe_mem Whether we should fail compilation if the computed frontend memory cache size is below a certain limit (def 150 GB)
# @param check_min_fe_mem_value If the computed frontend memory cache size is below this value and check_min_fe_mem is set, fail Puppet compilation
# @param fe_beacon_uri_regex
#   URI path regex to use when intercepting '/beacon' URIs to return a synthetic 204.
#   For e.g. /beacon/statsv, etc.  If undefined, this feature will be disabled.
#   The default matches everything except /beacon/event, as this endpoint has been
#   removed as part of https://phabricator.wikimedia.org/T238230.
#   Default: '^/beacon\/(?!event)[^/?]+'
class profile::cache::varnish::frontend (
    # Globals
    String                  $conftool_prefix         = lookup('conftool_prefix'),
    Boolean                 $has_lvs                 = lookup('has_lvs', { 'default_value'                                                   => true }),
    # TODO: fix theses so they re under the profile namespace
    Hash[String, Hash]      $cache_nodes             = lookup('cache::nodes'),
    String                  $cache_cluster           = lookup('cache::cluster'),
    Profile::Cache::Sites   $req_handling            = lookup('cache::req_handling'),
    Profile::Cache::Sites   $alternate_domains       = lookup('cache::alternate_domains', { 'default_value'                                  => {} }),
    Boolean                 $single_backend          = lookup('profile::cache::varnish::frontend::single_backend', { 'default_value'         => true }),
    # locals
    Hash[String, Any]       $fe_vcl_config           = lookup('profile::cache::varnish::frontend::fe_vcl_config'),
    Hash[String, Any]       $fe_cache_be_opts        = lookup('profile::cache::varnish::frontend::cache_be_opts'),
    Boolean                 $backends_in_etcd        = lookup('profile::cache::varnish::frontend::backends_in_etcd'),
    Array[String]           $fe_extra_vcl            = lookup('profile::cache::varnish::frontend::fe_extra_vcl'),
    Array[String]           $runtime_params          = lookup('profile::cache::varnish::frontend::runtime_params'),
    String                  $packages_component      = lookup('profile::cache::varnish::frontend::packages_component'),
    Array[String]           $separate_vcl            = lookup('profile::cache::varnish::frontend::separate_vcl'),
    Integer                 $fe_transient_gb         = lookup('profile::cache::varnish::frontend::transient_gb'),
    Array[Stdlib::Unixpath] $listen_uds              = lookup('profile::cache::varnish::frontend::listen_uds'),
    String                  $uds_owner               = lookup('profile::cache::varnish::frontend::uds_owner'),
    String                  $uds_group               = lookup('profile::cache::varnish::frontend::uds_group'),
    Stdlib::Filemode        $uds_mode                = lookup('profile::cache::varnish::frontend::uds_mode'),
    Stdlib::Unixpath        $privileged_uds          = lookup('profile::cache::varnish::frontend::privileged_uds', { 'default_value'         => '/run/varnish-privileged.socket' }),
    Boolean                 $use_etcd_req_filters    = lookup('profile::cache::varnish::frontend::use_etcd_req_filters'),
    Boolean                 $use_ip_reputation       = lookup('profile::cache::varnish::frontend::use_ip_reputation'),
    Boolean                 $use_private_repo        = lookup('profile::cache::varnish::frontend::use_private_repo', { 'default_value' => false }),
    Boolean                 $do_esitest              = lookup('profile::cache::varnish::frontend::do_esitest', { 'default_value'             => false }),
    Boolean                 $enable_monitoring       = lookup('profile::cache::varnish::frontend::enable_monitoring'),
    Optional[String]        $fe_jemalloc_conf        = lookup('profile::cache::varnish::frontend::fe_jemalloc_conf', { 'default_value'       => undef }),
    Integer[1]              $thread_pool_max         = lookup('profile::cache::varnish::frontend::thread_pool_max'),
    Optional[String]        $vsl_size                = lookup('profile::cache::varnish::frontend::vsl_size', { 'default_value'               => '160M' }),
    Optional[Integer]       $fe_mem_gb_reserved      = lookup('profile::cache::varnish::frontend::fe_mem_gb_reserved', { 'default_value'     => 170 }),
    Boolean                 $check_min_fe_mem        = lookup('profile::cache::varnish::frontend::check_min_fe_mem', { 'default_value'       => false }),
    Optional[Integer]       $check_min_fe_mem_value  = lookup('profile::cache::varnish::frontend::check_min_fe_mem_value', { 'default_value' => 150 }),
    Optional[String]        $fe_beacon_uri_regex     = lookup('profile::cache::varnish::frontend::fe_beacon_uri_regex', { 'default_value'    => '^/beacon\/(?!event)[^/?]+' }),
    Boolean                 $do_edge_uniques         = lookup('profile::cache::varnish::frontend::do_edge_uniques', { 'default_value'        => false }),
    Stdlib::Unixpath        $edge_uniques_key_dir    = lookup('profile::cache::varnish::frontend::edge_uniques_key_path', { 'default_value'  => '/etc/varnish/uniques.d' }),
    Stdlib::Unixpath        $edge_uniques_cfg_path   = lookup('profile::cache::varnish::frontend::edge_uniques_cfg_path', { 'default_value'  => '/etc/varnish/uniques.json' }),
    Hash[String, Boolean]   $rate_limiting_flags     = lookup('profile::cache::varnish::frontend::rate_limiting_flags', { 'default_value' => { 'auth' => false, 'known' => false, 'bots' => false, 'unid' => false, 'browser' => false } }),
) {
    include profile::cache::base
    $wikimedia_nets = $profile::cache::base::wikimedia_nets
    $wikimedia_trust = $profile::cache::base::wikimedia_trust
    $wikimedia_domains = $profile::cache::base::wikimedia_domains
    $wmcs_domains = $profile::cache::base::wmcs_domains

    if $has_lvs {
        include profile::lvs::realserver
    }

    $packages = [
        'libvmod-netmapper',
        'libvmod-querysort',  # T138093
        'libvmod-wmfuniq',
        'varnish',
        'varnish-modules',
        'varnish-re2',
    ]
    # wmfuniq-experiment-fetcher python dependencies
    ensure_packages(['python3-jsonschema', 'python3-requests'])

    # We need these two services disabled as we don't use them.
    systemd::mask { 'varnishncsa.service': }
    systemd::mask { 'varnishlog.service': }

    if $packages_component == 'main' {
        package { $packages:
            ensure  => installed,
            before  => Mount['/var/lib/varnish'],
            require => [
                Systemd::Mask['varnishncsa.service'],
                Systemd::Mask['varnishlog.service'],
            ],
        }
    } else {
        apt::package_from_component { 'varnish':
            component => $packages_component,
            packages  => $packages,
            before    => Mount['/var/lib/varnish'],
            require   => [
                Systemd::Mask['varnishncsa.service'],
                Systemd::Mask['varnishlog.service'],
            ],
            priority  => 1002, # Take precedence over main
        }
    }

    $wmfuniq_secret_base_path = '/etc/varnish/uniques.d'
    file { $wmfuniq_secret_base_path:
        ensure    => bool2str($do_edge_uniques, 'directory', 'absent'),
        owner     => 'root',
        group     => 'varnish',
        mode      => '0750',
        show_diff => false,
        backup    => false,
    }

    $wmfuniq_secrets = wmflib::list_secrets('wmfuniq')
    $wmfuniq_secrets.each|String $secret| {
        file { "${wmfuniq_secret_base_path}/${secret.basename}":
            ensure    => bool2str($do_edge_uniques, 'file', 'absent'),
            owner     => 'root',
            group     => 'varnish',
            mode      => '0640',
            show_diff => false,
            backup    => false,
            content   => wmflib::secret($secret, true),
        }
    }

    file { '/usr/local/bin/wmfuniq-experiment-fetcher':
        ensure => bool2str($do_edge_uniques, 'file', 'absent'),
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/profile/cache/wmfuniq_experiment_fetcher.py',
    }

    systemd::timer::job { 'wmfuniq-experiment-fetcher':
        ensure             => bool2str($do_edge_uniques, 'present', 'absent'),
        description        => 'fetch edge uniques experiments configuration',
        user               => 'root',
        monitoring_enabled => true,
        send_mail          => true,
        environment        => { 'MAILTO' => 'sre-traffic@wikimedia.org' },
        interval           => { 'start' => 'OnCalendar', 'interval' => 'minutely' },
        accuracy           => '1s',
        splay              => 59,
        fixed_random_delay => true,
        command            => "/usr/local/bin/wmfuniq-experiment-fetcher ${edge_uniques_cfg_path}",
        require            => [File['/usr/local/bin/wmfuniq-experiment-fetcher'], Package['python3-jsonschema']],
    }

    # Mount /var/lib/varnish as tmpfs to avoid Linux flushing mlocked
    # shm memory to disk
    mount { '/var/lib/varnish':
        ensure  => mounted,
        device  => 'tmpfs',
        fstype  => 'tmpfs',
        options => 'noatime,defaults,size=512M',
        pass    => 0,
        dump    => 0,
    }

    # Frontend memory cache sizing
    $sys_mem_gb = $facts['memory']['system']['total_bytes'] / 1073741824.0
    if ($sys_mem_gb < ($fe_mem_gb_reserved + 1.0)) {
        # virtuals, test hosts, etc...
        $fe_mem_gb = 1
    } else {
        $fe_mem_gb = ceiling($sys_mem_gb - $fe_mem_gb_reserved)
    }

    # This check is inspired by T376737. TL;DR: we should have some sort of a
    # check during provisioning and bringing up a new host so that if the
    # physical memory is beneath a certain threshold, we should fail() and
    # abort the reimaging. Otherwise, $fe_mem_gb gets values such as 1, which
    # is not desirable for a prod instance.
    #
    # The value of 150 GB (the default) is simply derived from the minimum
    # physical memory as per https://wikitech.wikimedia.org/wiki/CDN/Hardware.
    # Subtracting $fe_mem_gb_reserved (default of 170), we pick a value of 150.
    # Even on config F2 and F3 (old configs) at the time of this commit
    # (codfw/drmrs), 404294909952 bytes of physical memory (376 Gi) should mean
    # that it is greater than 150 GB. Anything below that indicates issues with
    # the hardware so we should fail the reimaging and notify the user
    #
    # This would have prevented issues with T376737 above.
    if ($check_min_fe_mem and ($fe_mem_gb < $check_min_fe_mem_value)) {
        fail("We expected a minimum frontend memory of ${check_min_fe_mem_value} GB but computed ${fe_mem_gb} GB. Please check the physical memory on this host or override this value.")
    }

    $vcl_config = $fe_vcl_config + {
        req_handling                => $req_handling,
        alternate_domains           => $alternate_domains,
        fe_mem_gb                   => $fe_mem_gb,
        do_esitest                  => $do_esitest,
        beacon_uri_regex            => $fe_beacon_uri_regex,
        do_edge_uniques             => $do_edge_uniques,
        edge_uniques_key_path       => "${edge_uniques_key_dir}/keys.cfg",
        edge_uniques_cfg_path       => $edge_uniques_cfg_path,
    }

    # VCL files common to all instances
    class { 'varnish::common::vcl':
        vcl_config   => $vcl_config,
        private_repo => $use_private_repo,
    }

    $separate_vcl_frontend = $separate_vcl.map |$vcl| { "${vcl}-frontend" }

    # Single-backend nodes (Only drmrs can disable; All other DCs
    # forcibly use single_backend and cannot be adjusted due to ats-be
    # no longer being available as a confd service).
    if $single_backend {
        $backend_caches = [$facts['networking']['fqdn']]
        $etcd_backends = false
    } else {
        unless $::site == 'drmrs' {
            warning('Only drmrs can have single-backend CDN disabled')
        }
        $backend_caches = $cache_nodes[$cache_cluster][$::site]
        $etcd_backends = $backends_in_etcd
    }

    # Dynamic configuration sourced from etcd.
    $reload_vcl_opts = varnish::reload_vcl_opts($vcl_config['varnish_probe_ms'], $separate_vcl_frontend, 'frontend', "${cache_cluster}-frontend")

    $directors_keyspaces = ["${conftool_prefix}/pools/${::site}/cache_${cache_cluster}/ats-be"]

    # This is the etcd-driven list of backends for this frontend for chashing,
    # but deployment-prep and single-backend cases will have a false
    # $etcd_backends and thus hit ensure => absent below
    confd::file {
        '/etc/varnish/directors.frontend.vcl':
            ensure     => bool2str($etcd_backends, 'present', 'absent'),
            reload     => "/usr/local/bin/confd-reload-vcl varnish-frontend ${reload_vcl_opts}",
            before     => Service['varnish-frontend'],
            watch_keys => $directors_keyspaces,
            content    => template('profile/cache/varnish-frontend.directors.vcl.tpl.erb');
    }

    if $use_etcd_req_filters {
        $scopes = ['default', 'hit', 'deprecation', 'auth', 'bots']
        $scopes.each |$scope| {
            profile::cache::varnish::requestctl_rules_file { $scope:
                conftool_prefix => $conftool_prefix,
                cache_cluster   => $cache_cluster,
                reload_vcl_opts => $reload_vcl_opts,
            }
        }
        # Known-client rate limits.
        profile::cache::varnish::known_client_rate_limits_file { 'known-client-rate-limits':
            conftool_prefix => $conftool_prefix,
            cache_cluster   => $cache_cluster,
            reload_vcl_opts => $reload_vcl_opts,
        }
    } else {
        file { ['/etc/varnish/requestctl-filters.inc.vcl', '/etc/varnish/requestctl-filters-hit.inc.vcl', '/etc/varnish/blocked-nets.inc.vcl']:
            ensure => absent,
        }
    }

    # Transient storage limits T164768
    if $fe_transient_gb > 0 {
        $fe_transient_storage = "-s Transient=malloc,${fe_transient_gb}G"
    } else {
        $fe_transient_storage = ''
    }

    # Raise maximum number of memory map areas per process from 65530 to
    # $vm_max_map_count. See https://www.kernel.org/doc/Documentation/sysctl/vm.txt.
    # Varnish frontend crashes with "Error in munmap(): Cannot allocate
    # memory" are likely due to the varnish child process reaching this limit.
    # https://phabricator.wikimedia.org/T242417
    $vm_max_map_count = 262120

    sysctl::parameters { 'maximum map count':
        values => {
            'vm.max_map_count' => $vm_max_map_count,
        },
    }

    class { 'prometheus::node_varnishd_mmap_count':
        service => 'varnish-frontend.service',
    }

    # Monitor the mmap usage of varnish; Make sure it doesn't exceed the system limits
    class { 'prometheus::node_sysctl': }

    prometheus::node_varnish_params { 'prometheus-varnish-params':
        param_thread_pool_max => $thread_pool_max,
        outfile               => '/var/lib/prometheus/node.d/varnish_params.prom',
    }

    # Monitor number of varnish file descriptors. Initially added to track
    # T243634 but generally useful.
    prometheus::node_file_count { 'track vcache fds':
        paths   => ['/proc/$(pgrep -u vcache)/fd'],
        outfile => '/var/lib/prometheus/node.d/vcache_fds.prom',
        metric  => 'node_varnish_filedescriptors_total',
    }

    varnish::instance { "${cache_cluster}-frontend":
        instance_name     => 'frontend',
        # E.g. "text-frontend" or "upload-frontend"
        vcl               => "${cache_cluster}-frontend",
        separate_vcl      => $separate_vcl_frontend,
        extra_vcl         => $fe_extra_vcl,
        tcp_addrs         => ['127.0.0.1:3127'],
        admin_port        => 6082,
        runtime_params    => join(prefix($runtime_params, '-p '), ' '),
        storage           => "-s malloc,${fe_mem_gb}G ${fe_transient_storage}",
        jemalloc_conf     => $fe_jemalloc_conf,
        backend_caches    => $backend_caches,
        backend_options   => $fe_cache_be_opts,
        backends_in_etcd  => $etcd_backends,
        vcl_config        => $vcl_config,
        wikimedia_nets    => $wikimedia_nets,
        wikimedia_trust   => $wikimedia_trust,
        wikimedia_domains => $wikimedia_domains,
        wmcs_domains      => $wmcs_domains,
        listen_uds        => $listen_uds,
        uds_owner         => $uds_owner,
        uds_group         => $uds_group,
        uds_mode          => $uds_mode,
        privileged_uds    => $privileged_uds,
        enable_monitoring => $enable_monitoring,
        thread_pool_max   => $thread_pool_max,
        vsl_size          => $vsl_size,
        etcd_filters      => $use_etcd_req_filters,
        ip_reputation     => $use_ip_reputation,
        private_repo      => $use_private_repo,
        ratelimit_flags   => $rate_limiting_flags,
    }
}
