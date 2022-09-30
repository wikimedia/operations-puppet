# SPDX-License-Identifier: Apache-2.0
# @summary imanage BGPalerter
# @url https://github.com/nttgin/BGPalerter/blob/main/docs/configuration.md
# @param monitors array of monitors to configure
# @param reports array of reports to configure
# @param prefixes The prefixes to monitor.
#   use ./bgpalerter-linux-x64 generate -a $AS -o prefixes.yaml to generate
# @param prefixe_options The prefix options.  use the genrate command above to create config
# @param notification_interval_seconds Defines the amount of seconds after which an alert can be repeated.
# @param persist_status Persist the status of BGPalerter. If the process is restarted, the list of alerts
#   already sent is recovered
class bgpalerter (
    # defaults loaded from data/common.yaml
    Bgpalerter::Logging        $logging,
    Bgpalerter::Rpki           $rpki,
    Bgpalerter::Rest           $rest,
    Array[Bgpalerter::Report]  $reports,
    Array[Bgpalerter::Monitor] $monitors,

    Boolean                    $manage_user                         = false,
    String                     $user                                = 'bgpalerter',
    # ignore camel case as that's what the app uses
    # lint:ignore:variable_is_lowercase
    Integer                    $notificationIntervalSeconds         = 86400,
    Boolean                    $persistStatus                       = true,
    Boolean                    $checkForUpdatesAtBoot               = true,
    Integer                    $generatePrefixListEveryDays         = 0,
    Optional[Stdlib::HTTPUrl]  $httpProxy                           = undef,
    # lint:endignore
    Optional[Bgpalerter::Prefix::Options]         $prefixes_options = undef,
    Hash[Stdlib::IP::Address, Bgpalerter::Prefix] $prefixes         = {},
) {
    $base_dir = '/etc/bgpalerter'
    $working_dir = '/run/bgpalerter'
    $bgpalerter_bin = '/usr/local/bin/bgpalerter'
    $config_file = "${base_dir}/config.yaml"
    $prefix_file = "${base_dir}/prefixes.yaml"
    $log_dir = $logging['directory'] ? {
        Stdlib::Unixpath => $logging['directory'],
        default          => "${base_dir}/${logging['directory']}"
    }
    # list of params which are not config keys
    # hard code this as there is only one set of options that make senses
    $ris_connector = {
        'file'   => 'connectorRIS',
        'name'   => 'ris',
        'params' => {
            'carefulSubscription' => true,
            'url'                 => 'ws://ris-live.ripe.net/v1/ws/',
            'perMessageDeflate'   => true,
            'subscriptions'       => {
                'moreSpecific'  => true,
                'type'          => 'UPDATE',
                'host'          => undef,  # This seems empty in the generate config?
                'socketOptions' => {'includeRaw' => false},
            }
        }
    }
    $filter_params = ['name', 'user', 'manage_user', 'prefixes', 'prefixes_options']
    $config = wmflib::dump_params($filter_params) + {
        'connectors'                => [$ris_connector],
        'monitoredPrefixesFiles'    => [$prefix_file],
        # Advanced settings (Don't touch here!)
        'alertOnlyOnce'             => false,
        'fadeOffSeconds'            => 360,
        'checkFadeOffGroupsSeconds' => 30,
        'pidFile'                   => 'bgpalerter.pid',
        'maxMessagesPerSecond'      => 6000,
        'multiProcess'              => false,
        'environment'               => 'production',
        'configVersion'             => 2,
    }
    # TODO: install bgpalerter
    if $manage_user {
        systemd::sysuser { 'bgpalerter': }
    }
    file { $base_dir:
        ensure => directory,
    }
    file { $log_dir:
        ensure => directory,
        owner  => $user,
        mode   => '0755'
    }
    file { $working_dir:
        ensure => directory,
        owner  => $user,
        mode   => '0750'
    }
    file { $config_file:
        ensure  => file,
        mode    => '0444',
        content => $config.to_yaml,
    }
    $_prefixes = prefixes_options ? {
        undef   => $prefixes,
        default => $prefixes + {'options' => $prefixes_options},
    }
    file { $prefix_file:
        ensure  => file,
        mode    => '0444',
        content => $_prefixes.to_yaml,
    }
    systemd::service { 'bgpalerter':
        content   => template('bgpalerter/bgpalerter.service.erb'),
        subscribe => File["${base_dir}/config.yaml", "${base_dir}/prefixes.yaml"],
    }
}
