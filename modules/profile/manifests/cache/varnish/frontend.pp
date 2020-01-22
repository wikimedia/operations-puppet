class profile::cache::varnish::frontend (
    $cache_nodes = hiera('cache::nodes'),
    $cache_cluster = hiera('cache::cluster'),
    $conftool_prefix = hiera('conftool_prefix'),
    $fe_vcl_config = hiera('profile::cache::varnish::frontend::fe_vcl_config'),
    $fe_cache_be_opts = hiera('profile::cache::varnish::cache_be_opts'),
    $fe_jemalloc_conf = hiera('profile::cache::varnish::frontend::fe_jemalloc_conf'),
    $fe_extra_vcl = hiera('profile::cache::varnish::frontend::fe_extra_vcl'),
    $req_handling = hiera('cache::req_handling'),
    $alternate_domains = hiera('cache::alternate_domains', {}),
    $separate_vcl = hiera('profile::cache::varnish::separate_vcl', []),
    $fe_transient_gb = hiera('profile::cache::varnish::frontend::transient_gb', 0),
    $backend_services = hiera('profile::cache::varnish::frontend::backend_services', ['ats-be']),
    Boolean $has_lvs = lookup('has_lvs', {'default_value' => true}),
    Integer $vm_max_map_count = lookup('profile::cache::varnish::frontend::vm_max_map_count', {'default_value' => 65530}),
) {
    require ::profile::cache::base
    $wikimedia_nets = $profile::cache::base::wikimedia_nets
    $wikimedia_trust = $profile::cache::base::wikimedia_trust

    $directors = {
        'cache_local' => {
            'dc'       => $::site,
            'backends' => $cache_nodes[$cache_cluster]["${::site}_ats"],
            'be_opts'  => $fe_cache_be_opts,
        },
    }

    if $has_lvs {
        # TODO: convert to use profile::lvs::realserver
        class { '::lvs::realserver':
            realserver_ips => $lvs::configuration::service_ips[$cache_cluster][$::site],
        }
    }

    $vcl_config = $fe_vcl_config + {
        req_handling      => $req_handling,
        alternate_domains => $alternate_domains
    }

    # VCL files common to all instances
    class { 'varnish::common::vcl':
        vcl_config => $vcl_config,
    }

    $separate_vcl_frontend = $separate_vcl.map |$vcl| { "${vcl}-frontend" }

    # Backend caches used by this Frontend from Etcd
    $reload_vcl_opts = varnish::reload_vcl_opts($vcl_config['varnish_probe_ms'],
        $separate_vcl_frontend, 'frontend', "${cache_cluster}-frontend")

    $keyspaces = $backend_services.map |$service| {
        "${conftool_prefix}/pools/${::site}/cache_${cache_cluster}/${service}"
    }
    confd::file { '/etc/varnish/directors.frontend.vcl':
        ensure     => present,
        watch_keys => $keyspaces,
        content    => template('profile/cache/varnish-frontend.directors.vcl.tpl.erb'),
        reload     => "/usr/local/bin/confd-reload-vcl varnish-frontend ${reload_vcl_opts}",
        before     => Service['varnish-frontend'],
    }

    # Frontend memory cache sizing
    $mem_gb = $::memorysize_mb / 1024.0
    if ($mem_gb < 90.0) {
        # virtuals, test hosts, etc...
        $fe_mem_gb = 1
    } else {
        # Removing a constant factor before scaling helps with
        # low-memory hosts, as they need more relative space to
        # handle all the non-cache basics.
        $fe_mem_gb = ceiling(0.7 * ($mem_gb - 80.0))
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
    sysctl::parameters { 'maximum map count':
        values => {
            'vm.max_map_count' => $vm_max_map_count,
        }
    }

    class { 'prometheus::node_varnishd_mmap_count':
        service => 'varnish-frontend.service',
    }

    monitoring::check_prometheus { 'varnishd-mmap-count':
        description     => 'Varnish number of memory map areas',
        query           => "scalar(varnishd_mmap_count{instance=\"${::hostname}:9100\"})",
        method          => 'gt',
        warning         => $vm_max_map_count - 5000,
        critical        => $vm_max_map_count - 1000,
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Varnish',
        dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/cache-host-drilldown?fullscreen&orgId=1&panelId=76&var-site=${::site} prometheus/ops&var-instance=${::hostname}"],
    }

    # lint:ignore:arrow_alignment
    varnish::instance { "${cache_cluster}-frontend":
        instance_name      => 'frontend',
        layer              => 'frontend',
        vcl                => "${cache_cluster}-frontend",
        separate_vcl       => $separate_vcl_frontend,
        extra_vcl          => $fe_extra_vcl,
        ports              => [ '80', '3120', '3121', '3122', '3123', '3124', '3125', '3126', '3127' ],
        admin_port         => 6082,
        storage            => "-s malloc,${fe_mem_gb}G ${fe_transient_storage}",
        jemalloc_conf      => $fe_jemalloc_conf,
        backend_caches     => $directors,
        vcl_config         => $vcl_config,
        wikimedia_nets     => $wikimedia_nets,
        wikimedia_trust    => $wikimedia_trust,
    }
    # lint:endignore
}
