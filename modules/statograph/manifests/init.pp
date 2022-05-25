# SPDX-License-Identifier: Apache-2.0
# @summary Installs statograph and configures systemd timer
#
# @param api_key the api key for statuspage.io
# @param page_id the statuspage "page id" for the WMF main page
# @param ensure the ensureable parameter
# @param owner all files created by this module will be owned by this user
# @param group all files created by this module will be owned by this group
# @param mode all files created by this module will be managed with this mode
class statograph (
    Wmflib::Ensure                  $ensure  = 'ensure',
    Sensitive[String[1]]            $api_key = '',
    Sensitive[String[1]]            $page_id = '',
    String                          $owner   = 'root',
    String                          $group   = 'root',
    Stdlib::Filemode                $mode    = '0500',
    Hash[String, Statograph::Proxy] $proxies = {},
    Array[Statograph::Metric]       $metrics = [],
)
{
    $config_file = '/etc/statograph/config.yml'
    $job_command = "/usr/bin/statograph -c ${config_file} upload_metrics"

    ensure_packages('statograph', {'ensure' => $ensure})

    $config = {
        'statuspage' => {
            'api_key' => $api_key.unwrap,
            'page_id' => $page_id.unwrap,
        },
        'proxies'    => $proxies,
        'metrics'   => $metrics,
    }

    file {'/etc/statograph':
        ensure => stdlib::ensure($ensure, 'directory'),
        owner  => $owner,
        group  => $group,
        mode   => $mode,
    }

    file {$config_file:
        ensure  => stdlib::ensure($ensure, 'file'),
        owner   => $owner,
        group   => $group,
        mode    => $mode,
        content => $config.to_yaml,
        require => Package['statograph'],
    }

    systemd::timer::job { 'statograph_post':
        ensure             => $ensure,
        description        => 'Runs statograph to publish data to statuspage.io',
        user               => $owner,
        monitoring_enabled => true,
        command            => $job_command,
        interval           => {'start' => 'OnCalendar', 'interval' => 'minutely'},
        require            => [
            File[$config_file],
            Package['statograph'],
        ]
    }

}
