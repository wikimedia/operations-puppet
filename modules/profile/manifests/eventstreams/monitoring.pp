# == Class profile::eventstreams::monitoring
#   Sets up a script to check that the $stream_url responds and has data.
#
class profile::eventstreams::monitoring {
    $stream_url = 'https://stream.wikimedia.org/v2/stream/recentchange'
    nrpe::plugin { 'check_eventstreams':
        source => 'puppet:///modules/profile/eventstreams/check_eventstreams.sh',
    }


    $check_command_config_content = 'define command {
    command_name check_eventstreams
    command_line $USER4$/check_eventstreams $ARG1$
}'
    nagios_common::check_command::config { 'check_eventstreams':
        content => $check_command_config_content,
        owner   => 'root',
        group   => 'root',
    }

    monitoring::service { 'eventstreams_endpoint':
        description    => 'Check if active EventStreams endpoint is delivering messages.',
        check_interval => 30,
        retries        => 2,
        contact_group  => 'admins,analytics',
        notes_url      => 'https://wikitech.wikimedia.org/wiki/Event_Platform/EventStreams/Administration',
        check_command  => "check_eventstreams!${stream_url}",
    }
}
