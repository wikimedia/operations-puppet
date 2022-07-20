# @summary profile to configure frontend varnis cache
# @param cache_nodes list of all cache nodes
# @param cache_cluster name of cache cluster e.g. upload or text
# @param conftool_prefix the prefix to use for conftool
# @param fe_vcl_config A hash if vcl config
# @param runtime_params A hash of runtime parameters
# @param fe_jemalloc_conf jemalloc configuration
# @param fe_cache_be_opts hash of backend configs
# @param backends_in_etcd indicate if backends are in etcd
# @param fe_extra_vcl list of extra VCLs
# @param req_handling hash of domains request handling config
# @param alternate_domains List of domains handled by misc
# @param packages_component The package component to use for apt
# @param fe_transient_gb Amount of Transient=malloc to configure in GB
# @param separate_vcl list of addtional VCLs
# @param has_lvs Indicate of cache is behind LVS
# @param single_backend_experiment Feature flag to test single backend
# @param listen_uds list of uds for varnish
# @param uds_owner The owner of the uds sockets
# @param uds_group The group of the uds sockets
# @param uds_mode The mode of the uds sockets
# @param use_etcd_req_filters use confd dynamically generated rules
class profile::cache::varnish::frontend (
    # Globals
    String                  $conftool_prefix           = lookup('conftool_prefix'),
    Boolean                 $has_lvs                   = lookup('has_lvs', {'default_value' => true}),
    # TODO: fix theses so they re under the profile namespace
    Hash[String, Hash]      $cache_nodes               = lookup('cache::nodes'),
    String                  $cache_cluster             = lookup('cache::cluster'),
    Profile::Cache::Sites   $req_handling              = lookup('cache::req_handling'),
    Profile::Cache::Sites   $alternate_domains         = lookup('cache::alternate_domains', {'default_value' => {}}),
    Optional[Stdlib::Fqdn]  $single_backend_experiment = lookup('cache::single_backend_fqdn', {'default_value' => undef}),
    # locals
    Hash[String, Any]       $fe_vcl_config             = lookup('profile::cache::varnish::frontend::fe_vcl_config'),
    Hash[String, Any]       $fe_cache_be_opts          = lookup('profile::cache::varnish::frontend::cache_be_opts'),
    Boolean                 $backends_in_etcd          = lookup('profile::cache::varnish::frontend::backends_in_etcd'),
    String                  $fe_jemalloc_conf          = lookup('profile::cache::varnish::frontend::fe_jemalloc_conf'),
    Array[String]           $fe_extra_vcl              = lookup('profile::cache::varnish::frontend::fe_extra_vcl'),
    Array[String]           $runtime_params            = lookup('profile::cache::varnish::frontend::runtime_params'),
    String                  $packages_component        = lookup('profile::cache::varnish::frontend::packages_component'),
    Array[String]           $separate_vcl              = lookup('profile::cache::varnish::frontend::separate_vcl'),
    Integer                 $fe_transient_gb           = lookup('profile::cache::varnish::frontend::transient_gb'),
    Array[Stdlib::Unixpath] $listen_uds                = lookup('profile::cache::varnish::frontend::listen_uds'),
    String                  $uds_owner                 = lookup('profile::cache::varnish::frontend::uds_owner'),
    String                  $uds_group                 = lookup('profile::cache::varnish::frontend::uds_group'),
    Stdlib::Filemode        $uds_mode                  = lookup('profile::cache::varnish::frontend::uds_mode'),
    Boolean                 $use_etcd_req_filters      = lookup('profile::cache::varnish::frontend::use_etcd_req_filters'),
) {
    include profile::cache::base
    $wikimedia_nets = $profile::cache::base::wikimedia_nets
    $wikimedia_trust = $profile::cache::base::wikimedia_trust
    $wikimedia_domains = $profile::cache::base::wikimedia_domains
    $wmcs_domains = $profile::cache::base::wmcs_domains

    if $has_lvs {
        include profile::lvs::realserver
    }

    # Defaults for the vcl files
    # TODO: pass it down once we've refactored the varnish classes.
    Varnish::Wikimedia_vcl {
        etcd_filters  => $use_etcd_req_filters,
    }
    $packages = [
        'varnish',
        'varnish-modules',
        'libvmod-netmapper',
        'libvmod-re2',
    ] + ( $::realm ? {
        'labs'  => ['libvmod-querysort'],  # T138093
        default => [],
    } )

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
    # TODO: possibly convert this to facts['memory']['system']['total_bytes']
    $mem_gb = $facts['memorysize_mb'] / 1024.0
    if ($mem_gb < 90.0) {
        # virtuals, test hosts, etc...
        $fe_mem_gb = 1
    } else {
        # Removing a constant factor before scaling helps with
        # low-memory hosts, as they need more relative space to
        # handle all the non-cache basics.
        $fe_mem_gb = ceiling(0.7 * ($mem_gb - 100.0))
    }

    $vcl_config = $fe_vcl_config + {
        req_handling         => $req_handling,
        alternate_domains    => $alternate_domains,
        fe_mem_gb            => $fe_mem_gb,
    }

    # VCL files common to all instances
    class { 'varnish::common::vcl':
        vcl_config => $vcl_config,
    }

    $separate_vcl_frontend = $separate_vcl.map |$vcl| { "${vcl}-frontend" }

    # Experiment with single backend CDN nodes T288106
    if $single_backend_experiment {
        if $facts['networking']['fqdn'] == $single_backend_experiment {
            $backend_caches = [ $facts['networking']['fqdn'] ]
            $etcd_backends = false
        } else {
            $backend_caches = $cache_nodes[$cache_cluster][$::site] - $single_backend_experiment
            $etcd_backends = $backends_in_etcd
        }
        $confd_experiment_fqdn = $single_backend_experiment
    } else {
        $backend_caches = $cache_nodes[$cache_cluster][$::site]
        $etcd_backends = $backends_in_etcd
        $confd_experiment_fqdn = ''
    }

    # Dynamic configuration sourced from etcd.
    $reload_vcl_opts = varnish::reload_vcl_opts($vcl_config['varnish_probe_ms'],
        $separate_vcl_frontend, 'frontend', "${cache_cluster}-frontend")

    $directors_keyspaces = [ "${conftool_prefix}/pools/${::site}/cache_${cache_cluster}/ats-be" ]

    if $etcd_backends {
        confd::file {
            default:
                ensure => present,
                reload => "/usr/local/bin/confd-reload-vcl varnish-frontend ${reload_vcl_opts}",
                before => Service['varnish-frontend'],;
            # Backend caches used by this Frontend from Etcd
            '/etc/varnish/directors.frontend.vcl':
                watch_keys => $directors_keyspaces,
                content    => template('profile/cache/varnish-frontend.directors.vcl.tpl.erb'),;
            # Abuse networks
            '/etc/varnish/blocked-nets.inc.vcl':
                watch_keys => ['/request-ipblocks/abuse'],
                content    => template('profile/cache/blocked-nets.inc.vcl.tpl.erb'),
                prefix     => $conftool_prefix,;
            # New request filter actions based on the content of the
            # /request-vcl tree in conftool.
            # Not enabled right now, will be in a future patchset.
            '/etc/varnish/requestctl-filters.inc.vcl':
                watch_keys => ["/request-vcl/cache-${cache_cluster}"],
                content    => template('profile/cache/varnish-frontend-requestctl-filters.vcl.tpl.erb'),
                prefix     => $conftool_prefix,;
        }
    } else {
        # deployment-prep still uses the old template.
        $abuse_networks = network::parse_abuse_nets('varnish')
        file { '/etc/varnish/blocked-nets.inc.vcl':
            ensure  => present,
            content => template('profile/cache/blocked-nets.inc.vcl.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
        }

        file { [ '/etc/varnish/directors.frontend.vcl', '/etc/varnish/requestctl-filters.inc.vcl' ]:
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

    monitoring::check_prometheus { 'varnishd-mmap-count':
        description     => 'Varnish number of memory map areas',
        query           => "scalar(varnishd_mmap_count{instance=\"${facts['networking']['hostname']}:9100\"})",
        method          => 'gt',
        warning         => $vm_max_map_count - 5000,
        critical        => $vm_max_map_count - 1000,
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Varnish',
        dashboard_links => ["https://grafana.wikimedia.org/d/wiU3SdEWk/cache-host-drilldown?orgId=1&viewPanel=76&var-site=${::site} prometheus/ops&var-instance=${facts['networking']['hostname']}"],
    }

    # Monitor number of varnish file descriptors. Initially added to track
    # T243634 but generally useful.
    prometheus::node_file_count {'track vcache fds':
        paths   => [ '/proc/$(pgrep -u vcache)/fd' ],
        outfile => '/var/lib/prometheus/node.d/vcache_fds.prom',
        metric  => 'node_varnish_filedescriptors_total',
    }

    varnish::instance { "${cache_cluster}-frontend":
        instance_name     => 'frontend',
        vcl               => "${cache_cluster}-frontend",
        separate_vcl      => $separate_vcl_frontend,
        extra_vcl         => $fe_extra_vcl,
        ports             => [ 80, 3120, 3121, 3122, 3123, 3124, 3125, 3126, 3127 ],
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
    }
}
