# SPDX-License-Identifier: Apache-2.0

class ip_reputation_vendors::spur_feeds (
    Wmflib::Ensure              $ensure        = 'present',
    String[1]                   $user          = 'nobody',
    String[1]                   $group         = 'nogroup',
    Hash[String, Any]           $configuration = {},
    Stdlib::Unixpath            $outdir        = '/srv/geoip',
    Optional[Stdlib::HTTPUrl]   $http_proxy    = undef,
){
    ensure_packages(['curl',])

    $proxy_env = $http_proxy ? {
        undef   => {},
        default => Hash( ['http_proxy', 'https_proxy' ].map |$env| {[$env, $http_proxy, $env.upcase, $http_proxy]}.flatten)
    }

    $token_env = $configuration['headers'] ? {
        undef   => {},
        default => {'SPUR_TOKEN' => $configuration['headers']['Token']}
    }

    $environment = $proxy_env + $token_env
    $command = '/usr/local/sbin/fetch_spur_proxy'

    file { $command:
        ensure => stdlib::ensure($ensure, 'file'),
        mode   => '0554',
        group  => $group,
        source => 'puppet:///modules/ip_reputation_vendors/fetch_spur_proxy.sh',
    }

    systemd::timer::job { 'dump_proxy_ranges':
        ensure            => $ensure,
        command           => "${command} ${outdir}/spur-proxy.mmdb",
        description       => 'Job to update known proxies',
        user              => $user,
        logging_enabled   => true,
        syslog_identifier => 'fetch-spur-proxy-feed',
        environment       => $environment,
        interval          => {'start' => 'OnCalendar', 'interval' => 'daily'},
    }

}
