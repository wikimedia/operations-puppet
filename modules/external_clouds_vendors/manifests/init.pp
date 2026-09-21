# SPDX-License-Identifier: Apache-2.0
# @summary class to install automatic updating of the cloud ip ranges in conftool
# @param ensure ensurable
# @param user user to use for downloading file
# @param group to use for file permissions
# @param manage_user set to false if the user is managed elsewhere
# @param http_proxy http proxy server to use will be used for both http and https
# @param api_token the requestctl api token in case we're writing to requestctl
class external_clouds_vendors (
    Wmflib::Ensure            $ensure       = 'present',
    String[1]                 $user         = 'external-clouds-fetcher',
    String[1]                 $group        = 'root',
    Boolean                   $manage_user  = true,
    Optional[Stdlib::HTTPUrl] $http_proxy   = undef,
    Optional[String]          $api_token    = undef,
) {
    if (!$api_token) {
        fail('You need to provide a API token to interact with requestctl.')
    }

    ensure_packages(['python3-lxml', 'python3-netaddr', 'python3-requests', 'python3-wmflib', 'python3-conftool', 'python3-git'])
    if $manage_user {
        systemd::sysuser { $user:
            description => 'User used for downloading external cloud vendor networks',
            before      => [
                File['/usr/local/bin/fetch-external-clouds-vendors-nets'],
                Systemd::Timer::Job['dump_cloud_ip_ranges']
            ],
        }
    }
    $proxy_env = $http_proxy ? {
        undef   => {},
        default => Hash(['http_proxy', 'https_proxy'].map |$env| {[$env, $http_proxy, $env.upcase, $http_proxy] }.flatten)
    }
    $environment = $api_token ? {
        undef => $proxy_env,
        default => $proxy_env + { 'REQUESTCTL_API_TOKEN' => $api_token }
    }

    file { '/usr/local/bin/fetch-external-clouds-vendors-nets':
        ensure => stdlib::ensure($ensure, 'file'),
        mode   => '0554',
        owner  => $user,
        group  => $group,
        source => 'puppet:///modules/external_clouds_vendors/fetch_external_clouds_vendors_nets.py',
    }

    systemd::timer::job { 'dump_cloud_ip_ranges':
        ensure            => $ensure,
        command           => '/usr/local/bin/fetch-external-clouds-vendors-nets -vvv',
        description       => 'Job to update list of cloud ip ranges',
        user              => $user,
        logging_enabled   => true,
        syslog_identifier => 'fetch-external-clouds-vendors-nets',
        environment       => $environment,
        interval          => { 'start' => 'OnCalendar', 'interval' => 'daily' },
        team              => 'Traffic',
    }
}
