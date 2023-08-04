# SPDX-License-Identifier: Apache-2.0
# @summary class to install automatic updataing of the public_clous.json netmapper file
# @param ensure ensurable
# @param user user to use for downloading file
# @param group to use for file permissions
# @param manage_user set to false if the user is managed elsewhere
# @param proxy_families the proxy families to donwload information about
# @param outfile location to write the results
# @param http_proxy http proxy server to use will be used for both http and https
class ip_reputation_vendors (
    Wmflib::Ensure            $ensure         = 'present',
    String[1]                 $user           = 'ip-reputation-fetcher',
    String[1]                 $group          = 'root',
    Boolean                   $manage_user    = true,
    Array[String]             $proxy_families = [],
    Hash[String, Any]         $configuration  = {},
    Stdlib::Unixpath          $outfile        = '/srv/ip_reputation_vendors/proxies.json',
    Optional[Stdlib::HTTPUrl] $http_proxy     = undef,
) {
    ensure_packages(['python3-netaddr', 'python3-requests'])
    if $manage_user {
        systemd::sysuser { $user:
            description => 'User designed for downloading external ip reputation data',
            before      => [
                File[$outfile.dirname(), $outfile, '/usr/local/bin/fetch-ip-reputation-vendors'],
                Systemd::Timer::Job['dump_ip_reputation']
            ],
        }
    }
    $environment = $http_proxy ? {
        undef   => {},
        default => Hash( ['http_proxy', 'https_proxy' ].map |$env| {[$env, $http_proxy, $env.upcase, $http_proxy]}.flatten)
    }
    file { $outfile.dirname():
        ensure => stdlib::ensure($ensure, 'directory'),
        owner  => $user,
        group  => $group,
    }
    file { '/usr/local/bin/fetch-ip-reputation-vendors':
        ensure => stdlib::ensure($ensure, 'file'),
        mode   => '0554',
        owner  => $user,
        group  => $group,
        source => 'puppet:///modules/ip_reputation_vendors/fetch_ip_reputation_vendors.py',
    }

    $config_file = '/etc/fetch-ip-reputation-vendors.config'
    file { $config_file:
        ensure  => stdlib::ensure($ensure, 'file'),
        mode    => '0554',
        owner   => $user,
        group   => $group,
        content => to_json($configuration),
        before  => Systemd::Timer::Job['dump_ip_reputation']
    }

    file { $outfile:
        ensure  => stdlib::ensure($ensure, 'file'),
        mode    => '0644',
        owner   => $user,
        group   => $group,
        # set replace false to ensure we only create content if no file already exists
        replace => false,
        content => '{}',
    }
    $opts = $proxy_families.join(' ')
    $command = "/usr/local/bin/fetch-ip-reputation-vendors -vv -c ${config_file} -o ${outfile} ${opts}"
    systemd::timer::job { 'dump_ip_reputation':
        ensure            => $ensure,
        command           => $command,
        description       => 'Job to update ip reputation data',
        user              => $user,
        logging_enabled   => true,
        syslog_identifier => 'fetch-ip-reputation-vendors',
        environment       => $environment,
        interval          => {'start' => 'OnCalendar', 'interval' => 'daily'},
    }
}

