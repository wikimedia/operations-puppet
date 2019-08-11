# Definition: nrpe::monitor_service
#
# Defines a Nagios check for a remote service over NRPE
#
# Also optionally installs a corresponding NRPE check file
# using nrpe::check
#
# Parameters
#    $notes_url
#       A required URL used to provide information about the service.
#       Ideally a runbook how to handle alerts on Wikitech. Must not be URL-encoded.
#    $description
#       Service check description
#    $nrpe_command
#       The path to the actual binary/script. A stanza for nrpe daemon will be
#       added with that path and a nagios_service check will be exported to
#       nagios server.
#    $contact_group
#       Defaults to admins, the nagios contact group for the service
#    $retries
#       Defaults to 3. The number of times a service will be retried before
#       notifying
#    $timeout
#       Defaults to 10. The check timeout in seconds (check_nrpe -t option)
#    $critical
#       Defaults to false. If true, this will be a paging alert.
#    $event_handler
#       Default to false. If present execute this registered command on the
#       Nagios server.
#    $dashboard_link
#       An optional URL to link to grafana or another monitoring dashboard.
#       Must not be URL-encoded.
#    $ensure
#       Defaults to present
#
define nrpe::monitor_service( Optional[Stdlib::HTTPSUrl] $notes_url = undef,
                              $description      = undef,
                              $nrpe_command     = undef,
                              $contact_group    = hiera('contactgroups', 'admins'),
                              $retries          = 3,
                              $timeout          = 10,
                              Boolean $critical = false,
                              $event_handler    = undef,
                              $check_interval   = 1,
                              $retry_interval   = 1,
                              Optional[Array[Stdlib::HTTPSUrl, 1]] $dashboard_links = undef,
                              Wmflib::Ensure $ensure = present) {
    unless $ensure == 'absent' or ($description and $nrpe_command and $notes_url) {
        fail('Description, nrpe_command, and notes_url parameters are mandatory for ensure != absent')
    }
    nrpe::check { "check_${title}":
        ensure  => $ensure,
        command => $nrpe_command,
        before  => Monitoring::Service[$title],
    }

    $notes_urls = monitoring::build_notes_url($notes_url,
        ($dashboard_links) ? {undef => [], default => $dashboard_links})

    monitoring::service { $title:
        ensure         => $ensure,
        description    => $description,
        check_command  => "nrpe_check!check_${title}!${timeout}",
        contact_group  => $contact_group,
        retries        => $retries,
        critical       => $critical,
        event_handler  => $event_handler,
        check_interval => $check_interval,
        retry_interval => $retry_interval,
        notes_url      => $notes_urls,
    }
}
