# === Class profile::cache::base
#
# Sets up some common things for cache instances:
# - conftool
# - monitoring
# - logging/analytics
# - storage
#
class profile::cache::base(
    $cache_cluster = hiera('cache::cluster'),
    $statsd_host = hiera('statsd'),
    $zero_site = hiera('profile::cache::base::zero_site'),
    $purge_host_only_upload_re = hiera('profile::cache::base::purge_host_only_upload_re'),
    $purge_host_not_upload_re = hiera('profile::cache::base::purge_host_not_upload_re'),
    $storage_parts = hiera('profile::cache::base::purge_host_not_upload_re'),
    $packages_version = hiera('profile::cache::base::packages_version', 'installed'),
    $varnish_version = hiera('profile::cache::base::varnish_version', 4),
    $purge_host_regex = hiera('profile::cache::base::purge_host_regex', ''),
    $purge_multicasts = hiera('profile::cache::base::purge_multicasts', ['239.128.0.112']),
    $purge_varnishes = hiera('profile::cache::base::purge_varnishes', ['127.0.0.1:3128', '127.0.0.1:3127']),
    $fe_runtime_params = hiera('profile::cache::base::fe_runtime_params', []),
    $be_runtime_params = hiera('profile::cache::base::be_runtime_params', []),
    $logstash_host = hiera('logstash_host', undef),
    $logstash_syslog_port = hiera('logstash_syslog_port', undef),
    $logstash_json_port = hiera('logstash_json_port', undef),
    $log_slow_request_threshold = hiera('profile::cache::base::log_slow_request_threshold', '60.0'),
    $allow_iptables = hiera('profile::cache::base::allow_iptables', false),
) {
    # There is no better way to do this, so it can't be a class parameter. In fact,
    # I consider our requirement to make hiera calls parameters
    # harmful, as it prevents us to do hiera key interpolation in
    # subsequent hiera calls, but we did this because of the way the
    # WM Cloud puppet UI works. meh. So, just disable the linter here.
    # lint:ignore:wmf_styleguide
    $nodes = hiera("cache::${cache_cluster}::nodes")
    # lint:endignore

    # Needed profiles
    require ::profile::conftool::client
    require ::profile::prometheus::varnish_exporter
    require ::profile::cache::ssl::unified
    require ::standard

    # FIXME: this cannot be required or it will cause a dependency cycle. It might be a good idea not to include it here
    include ::profile::cache::kafka::webrequest

    # Globals we need to include
    include ::lvs::configuration
    include ::network::constants

    if ! $allow_iptables {
        # Prevent accidental iptables module loads
        kmod::blacklist { 'cp-bl':
            modules => ['x_tables'],
        }
    }

    class { 'conftool::scripts': }

    # TODO: Spin off a profile::cache::base::production?
    if $::realm == 'production' {
        # Only production needs system perf tweaks
        class { '::cpufrequtils': }
        class { 'cacheproxy::performance': }
        # Periodic cron restarts, we need this to mitigate T145661
        class { 'cacheproxy::cron_restart':
            nodes         => $nodes,
            cache_cluster => $cache_cluster,
        }
    }
    # Basic varnish classes
    class { '::varnish::packages':
        version         => $packages_version,
        varnish_version => $varnish_version,
    }

    class { '::varnish::common':
        varnish_version            => $varnish_version,
        fe_runtime_params          => $fe_runtime_params,
        be_runtime_params          => $be_runtime_params,
        log_slow_request_threshold => $log_slow_request_threshold,
        logstash_host              => $logstash_host,
        logstash_json_port         => $logstash_json_port,
    }

    class { [
        '::varnish::common::errorpage',
        '::varnish::common::browsersec',
    ]:
    }

    class { 'varnish::zero_update':
        site         => $zero_site,
    }

    ###########################################################################
    # Analytics/Logging stuff
    ###########################################################################
    if $logstash_host != undef and $logstash_syslog_port != undef {
        $forward_syslog = "${logstash_host}:${logstash_syslog_port}"
    } else {
        $forward_syslog = ''
    }

    class { '::varnish::logging':
        cache_cluster  => $cache_cluster,
        statsd_host    => $statsd_host,
        forward_syslog => $forward_syslog,
    }

    # auto-depool on shutdown + conditional one-shot auto-pool on start
    class { 'cacheproxy::traffic_pool': }


    ###########################################################################
    # Storage configuration
    ###########################################################################

    # everything from here down is related to backend storage/weight config

    $storage_size = $::hostname ? {
        /^cp1008$/              => 117, # Intel X-25M 160G (test host!)
        /^cp30(0[3-9]|10)$/     => 460, # Intel M320 600G via H710
        /^cp400[1234]$/         => 220, # Seagate ST9250610NS - 250G (only non-SSD left!)
        /^cp40(2[1-9]|3[0-2])$/ => 730, # Intel S3710 800G (new default 2017)
        /^cp[0-9]{4}$/          => 360, # Intel S3700 400G (old default pre-2017)
        default                 => 6,   # 6 is the bare min, for e.g. virtuals
    }

    $filesystems = unique($storage_parts)
    varnish::setup_filesystem { $filesystems: }
    Varnish::Setup_filesystem <| |> -> Varnish::Instance <| |>

    $file_storage_args = join([
        "-s main1=file,/srv/${storage_parts[0]}/varnish.main1,${storage_size}G",
        "-s main2=file,/srv/${storage_parts[1]}/varnish.main2,${storage_size}G",
    ], ' ')

    ###########################################################################
    # Purging
    ###########################################################################
    class { 'varnish::htcppurger':
        host_regex => $purge_host_regex,
        mc_addrs   => $purge_multicasts,
        varnishes  => $purge_varnishes,
    }
}
