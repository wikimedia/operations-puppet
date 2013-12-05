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
#    $ensure
#       Defaults to present
#
define nrpe::monitor_service( $description,
                              $nrpe_command,
                              $contact_group = 'admins',
                              $retries       = 3,
                              $timeout       = 10,
                              $ensure        = 'present') {

    nrpe::check { "check_${title}":
        command => $nrpe_command,
        before  => ::Monitor_service[$title],
    }

    # TODO: Refactor this to make a call to nagios::monitor_service (or similar) after nagios
    # has been refactored to a module. It is known to cause rspec tests to fail
    ::monitor_service { $title:
        ensure        => $ensure,
        description   => $description,
        check_command => "nrpe_check!check_${title}!${timeout}",
        contact_group => $contact_group,
        retries       => $retries,
    }
}
