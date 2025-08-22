# SPDX-License-Identifier: Apache-2.0

class ip_reputation_vendors::spur_datacenter (
    Wmflib::Ensure      $ensure           = 'present',
    String[1]           $user             = 'nobody',
    String[1]           $group            = 'nobody',
    Hash[String, Any]   $configuration    = {},
    Stdlib::Unixpath    $outfile          = '/tmp/datacenter.mmdb',
    Stdlib::Unixpath    $tmpdir           = '/tmp/',
    Optional[Stdlib::HTTPUrl] $http_proxy = undef,
) {
    ensure_packages([
        'libjson-perl',
        'libmaxmind-db-writer-perl',
        'libwww-perl'
    ])

    $proxy_env = $http_proxy ? {
        undef   => {},
        default => Hash( ['http_proxy', 'https_proxy' ].map |$env| {[$env, $http_proxy, $env.upcase, $http_proxy]}.flatten)
    }

    $token_env = $configuration['headers'] ? {
        undef   => {},
        default => {'SPUR_TOKEN' => $configuration['headers']['Token']}
    }

    $environment = $proxy_env + $token_env

    file { '/usr/local/bin/fetch-datacenter-vendors':
        ensure => stdlib::ensure($ensure, 'file'),
        mode   => '0554',
        group  => $group,
        source => 'puppet:///modules/ip_reputation_vendors/fetch_datacenter_vendors.pl',
    }

    $command = "/usr/local/bin/fetch-datacenter-vendors -f ${tmpdir}dch_latest.json -o ${outfile}"

    systemd::timer::job { 'dump_datacenter_ranges':
        ensure            => absent,  # Absent for now, will be enabled after testing.
        command           => $command,
        description       => 'Job to update known datacenter database',
        user              => $user,
        logging_enabled   => true,
        syslog_identifier => 'fetch-datacenter-vendors',
        environment       => $environment,
        interval          => {'start' => 'OnCalendar', 'interval' => 'daily'},
    }

}
