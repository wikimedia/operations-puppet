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
    $storage_parts = hiera('profile::cache::base::storage_parts'),
    $packages_version = hiera('profile::cache::base::packages_version', 'installed'),
    $varnish_version = hiera('profile::cache::base::varnish_version', 5),
    $purge_host_regex = hiera('profile::cache::base::purge_host_regex', ''),
    $purge_multicasts = hiera('profile::cache::base::purge_multicasts', ['239.128.0.112']),
    $purge_varnishes = hiera('profile::cache::base::purge_varnishes', ['127.0.0.1:3128', '127.0.0.1:3127']),
    $fe_runtime_params = hiera('profile::cache::base::fe_runtime_params', []),
    $be_runtime_params = hiera('profile::cache::base::be_runtime_params', []),
    $logstash_host = hiera('logstash_host', undef),
    $logstash_syslog_port = hiera('logstash_syslog_port', undef),
    $logstash_json_lines_port = hiera('logstash_json_lines_port', undef),
    $log_slow_request_threshold = hiera('profile::cache::base::log_slow_request_threshold', '60.0'),
    $allow_iptables = hiera('profile::cache::base::allow_iptables', false),
    $max_core_rtt = hiera('max_core_rtt'),
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
        logstash_json_lines_port   => $logstash_json_lines_port,
    }

    class { [
        '::varnish::common::errorpage',
        '::varnish::common::browsersec',
    ]:
    }

    class { 'varnish::zero_update':
        site         => $zero_site,
    }

    class { 'varnish::trusted_proxies': }

    # Varnish probes normally take 2xRTT, so for WAN cases give them
    # an outer max of 3xRTT, + 100ms for local hiccups
    $core_probe_timeout_ms = ($max_core_rtt * 3) + 100

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
        /^cp1008$/                 => 117,  # Intel X-25M 160G (test host!)
        /^cp30(0[789]|10)$/        => 460,  # Intel M320 600G via H710 (esams misc)
        /^cp[45]0[0-9]{2}$/        => 730,  # Intel S3710 800G (ulsfo + eqsin)
        /^cp10(7[5-9]|8[0-9]|90)$/ => 1490, # Samsung PM1725a 1.6T (new eqiad nodes)
        /^cp[0-9]{4}$/             => 360,  # Intel S3700 400G (codfw, esams text/upload, legacy eqiad)
        default                    => 6,    # 6 is the bare min, for e.g. virtuals
    }

    $filesystems = unique($storage_parts)
    varnish::setup_filesystem { $filesystems: }
    Varnish::Setup_filesystem <| |> -> Varnish::Instance <| |>
    $file_storage_args = join($filesystems.map |$idx, $store| { "-s main${$idx + 1}=file,/srv/${store}/varnish.main${$idx + 1},${storage_size}G" }, ' ')

    ###########################################################################
    # Purging
    ###########################################################################
    class { 'varnish::htcppurger':
        host_regex => $purge_host_regex,
        mc_addrs   => $purge_multicasts,
        varnishes  => $purge_varnishes,
    }
    Class[varnish::packages] -> Class[varnish::htcppurger]

    # new kernel packages for the new eqiad nodes - T203194
    # get rid of it as soon as kernel >= 4.9.134 is available on stretch
    $new_kernel = $::hostname ? {
        /^cp10(7[5-9]|8[0-9]|90)$/ => present,
        default                    => absent,
    }

    apt::repository { 'wikimedia-kernel-updates':
        ensure     => $new_kernel,
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => 'stretch-wikimedia',
        components => 'component/kernel-proposed-updates',
    }
}
