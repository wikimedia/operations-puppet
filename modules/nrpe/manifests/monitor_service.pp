# Definition: nrpe::monitor_service
#
# Defines a Nagios check for a remote service over NRPE
#
# Also optionally installs a corresponding NRPE check file
# using nrpe::check
#
# Parameters
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
#       Defaults to false. It will passed directly to monitoring::service which
#       will use nagios_service, so extra care, it is not a boolean, it is a string
#    $event_handler
#       Default to false. If present execute this registered command on the
#       Nagios server.
#    $notes_url
#       An optional URL used to provide more information about the service.
#    $ensure
#       Defaults to present
#
define nrpe::monitor_service( $description    = undef,
                              $nrpe_command   = undef,
                              $contact_group  = hiera('contactgroups', 'admins'),
                              $retries        = 3,
                              $timeout        = 10,
                              $critical       = false,
                              $event_handler  = undef,
                              $check_interval = 1,
                              $retry_interval = 1,
                              $notes_url      = undef,
                              Wmflib::Ensure $ensure = present) {
    unless $ensure == 'absent' or ($description and $nrpe_command) {
        fail('Description and nrpe_command parameters are mandatory for ensure != absent')
    }
    nrpe::check { "check_${title}":
        ensure  => $ensure,
        command => $nrpe_command,
        before  => Monitoring::Service[$title],
    }

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
        notes_url      => $notes_url,
    }
}
