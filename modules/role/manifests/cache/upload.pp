class role::cache::upload(
    $upload_domain = 'upload.wikimedia.org',
) {
    include role::cache::2layer
    include role::cache::ssl::unified
    include ::standard
    if $::standard::has_ganglia {
        include varnish::monitoring::ganglia::vhtcpd
    }

    class { 'varnish::htcppurger':
        host_regex => 'upload',
        mc_addrs   => [ '239.128.0.112', '239.128.0.113' ],
    }

    class { 'lvs::realserver':
        realserver_ips => $lvs::configuration::service_ips['upload'][$::site],
    }

    $fe_cache_be_opts = {
        'port'                  => 3128,
        'connect_timeout'       => '5s',
        'first_byte_timeout'    => '35s',
        'max_connections'       => 100000,
        'probe'                 => 'varnish',
    }

    $be_cache_be_opts = {
        'port'                  => 3128,
        'connect_timeout'       => '5s',
        'first_byte_timeout'    => '35s',
        'max_connections'       => 10000,
        'probe'                 => 'varnish',
    }

    $apps = hiera('cache::upload::apps')
    $app_directors = {
        'swift'   => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => $apps['swift']['backends'][$apps['swift']['route']],
            'be_opts'  => {
                'port'                  => 80,
                'connect_timeout'       => '5s',
                'first_byte_timeout'    => '35s',
                'max_connections'       => 10000,
            }
        },
        'swift_thumbs'   => {
            'dynamic'  => 'no',
            'type'     => 'random',
            'backends' => $apps['swift_thumbs']['backends'][$apps['swift_thumbs']['route']],
            'be_opts'  => {
                'port'                  => 80,
                'connect_timeout'       => '5s',
                'first_byte_timeout'    => '35s',
                'max_connections'       => 10000,
            }
        },
    }

    $common_vcl_config = {
        'purge_host_regex' => $::role::cache::base::purge_host_only_upload_re,
        'upload_domain'    => $upload_domain,
        'allowed_methods'  => '^(GET|HEAD|OPTIONS|PURGE)$',
    }

    # Note pass_random true in BE, false in FE below.
    # upload VCL has known FE->BE differentials on pass decisions:
    # 1. FEs pass all range reqs, BEs pass only those which start >32MB
    # 2. FEs pass all objs >32MB in size, BEs do not
    # Because of this, pass_random does more harm than good in the
    # upload-frontend case.  All tiers of backend share the same policies.

    $upload_storage_experiment = hiera('upload_storage_experiment', false)

    $be_vcl_config = merge($common_vcl_config, {
        'upload_storage_experiment' => $upload_storage_experiment,
        'pass_random'               => true,
    })

    $fe_vcl_config = merge($common_vcl_config, {
        'ttl_cap'          => '1d',
        'pass_random'      => false,
    })

    if $upload_storage_experiment {
        $sda = $::role::cache::2layer::storage_parts[0]
        $sdb = $::role::cache::2layer::storage_parts[1]
        $ssm = $::role::cache::2layer::storage_size * 2 * 1024
        $bin0_size = floor($ssm * 0.03)
        $bin1_size = floor($ssm * 0.20)
        $bin2_size = floor($ssm * 0.43)
        $bin3_size = floor($ssm * 0.30)
        $bin4_size = floor($ssm * 0.04)
        $upload_storage_args = join([
            "-s bin0=file,/srv/${sda}/varnish.bin0,${bin0_size}M",
            "-s bin1=file,/srv/${sdb}/varnish.bin1,${bin1_size}M",
            "-s bin2=file,/srv/${sda}/varnish.bin2,${bin2_size}M",
            "-s bin3=file,/srv/${sdb}/varnish.bin3,${bin3_size}M",
            "-s bin4=file,/srv/${sda}/varnish.bin4,${bin4_size}M",
        ], ' ')
    }
    else {
        if ($::role::cache::2layer::varnish_version4) {
            # The persistent storage backend is deprecated and buggy in Varnish 4.
            # Use "file" instead. See T142810, T142848 and
            # https://www.varnish-cache.org/docs/trunk/phk/persistent.html
            $storage_backend = 'file'
            $storage_mma_1 = ''
            $storage_mma_2 = ''
        }
        else {
            $storage_backend = 'persistent'
            $storage_mma_1 = ",${::role::cache::2layer::mma[0]}"
            $storage_mma_2 = ",${::role::cache::2layer::mma[1]}"
        }

        $storage_size_bigobj = floor($::role::cache::2layer::storage_size / 6)
        $storage_size_up = $::role::cache::2layer::storage_size - $storage_size_bigobj
        $upload_storage_args = join([
            "-s main1=${storage_backend},/srv/${::role::cache::2layer::storage_parts[0]}/varnish.main1,${storage_size_up}G${storage_mma_1}",
            "-s main2=${storage_backend},/srv/${::role::cache::2layer::storage_parts[1]}/varnish.main2,${storage_size_up}G${storage_mma_2}",
            "-s bigobj1=file,/srv/${::role::cache::2layer::storage_parts[0]}/varnish.bigobj1,${storage_size_bigobj}G",
            "-s bigobj2=file,/srv/${::role::cache::2layer::storage_parts[1]}/varnish.bigobj2,${storage_size_bigobj}G",
        ], ' ')
    }

    # default_ttl=7d
    $common_runtime_params = ['default_ttl=604800']

    # Bumping nuke_limit and lru_interval helps with T145661
    $be_runtime_params = ['nuke_limit=1000','lru_interval=31']

    role::cache::instances { 'upload':
        fe_mem_gb         => ceiling(0.4 * $::memorysize_mb / 1024.0),
        fe_jemalloc_conf  => 'lg_dirty_mult:8,lg_chunk:20',
        fe_runtime_params => $common_runtime_params,
        be_runtime_params => concat($common_runtime_params, $be_runtime_params),
        app_directors     => $app_directors,
        fe_vcl_config     => $fe_vcl_config,
        be_vcl_config     => $be_vcl_config,
        fe_extra_vcl      => ['upload-common'],
        be_extra_vcl      => ['upload-common'],
        be_storage        => $upload_storage_args,
        fe_cache_be_opts  => $fe_cache_be_opts,
        be_cache_be_opts  => $be_cache_be_opts,
        cluster_nodes     => hiera('cache::upload::nodes'),
    }

    # Media browser cache hit rate and request volume stats.
    ::varnish::logging::media { 'media':
        statsd_server => hiera('statsd'),
    }

    # XXX: temporary, we need this to mitigate T145661
    if $::realm == 'production' {
        $hnodes = hiera('cache::upload::nodes')
        $all_nodes = array_concat($hnodes['eqiad'], $hnodes['esams'], $hnodes['ulsfo'], $hnodes['codfw'])
        $times = cron_splay($all_nodes, 'daily', 'upload-backend-restarts')
        $be_restart_h = $times['hour']
        $be_restart_m = $times['minute']
        $be_restart_d = $times['weekday']

        file { '/etc/cron.d/varnish-backend-restart':
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            content => template('varnish/varnish-backend-restart.cron.erb'),
            require => File['/usr/local/sbin/varnish-backend-restart'],
        }
    }
}
