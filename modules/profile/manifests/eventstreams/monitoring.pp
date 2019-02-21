# == Class profile::eventstreams::monitoring
#   Sets up a script to check that the $stream_url responds and has data.
#
# == Parameters
#
# [*stream_url*]
#   EventStreams URL to check.
#
# [*use_nrpe*]
#   If true, nrpe::monitor_service will be used.
#   Use this if you are installing this check ON an eventstreams host itself.
#   If you are checking a remote endpoint e.g. from the icinga server,
#   this should be false. Default: false
#
class profile::eventstreams::monitoring (
    $stream_url = hiera('profile::eventstreams::monitoring', 'https://stream.wikimedia.org/v2/stream/recentchange'),
    $use_nrpe   = hiera('profile::eventstreams::monitoring', false),
) {
    file { '/usr/local/lib/nagios/plugins/check_eventstreams':
        ensure => 'present',
        source => 'puppet:///modules/profile/eventstreams/check_eventstreams.sh',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    $common_params = {
        'description'    => 'Check if active EventStreams endpoint is delivering messages.',
        'check_interval' => 30,
        'retries'        => 2,
        'contact_group'  => 'analytics',
        'require'        => File['/usr/local/lib/nagios/plugins/check_eventstreams'],
    }

    # Just use a remote nrpe check
    if $use_nrpe {
        $params = $common_params + {
            'nrpe_command' => "/usr/local/lib/nagios/plugins/check_eventstreams ${stream_url}",
        }
        ensure_resource('nrpe::monitor_service', 'eventstreams_endpoint', $params)
    }

    # Else use the check_command defined in checkcommands.cfg.erb.
    else {
        $params = $common_params + {
            'check_command' => "check_eventstreams!${stream_url}",
        }
        ensure_resource('monitoring::service', 'eventstreams_endpoint', $params)
    }
}