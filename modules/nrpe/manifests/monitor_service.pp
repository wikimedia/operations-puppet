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
#       If defined, installs this NRPE command as check_${title}
#    $contact_group
#       Defaults to admins, the nagios contact groupo for the service
#    $retries
#       Defaults to 3. The number of times a service will be retried before
#       notifying
#    $ensure
#       Defaults to present
#
define nrpe::monitor_service( $description,
                              $nrpe_command  = undef,
                              $contact_group = 'admins',
                              $retries       = 3,
                              $ensure        = 'present') {
    if $nrpe_command != undef {
        nrpe::check { "check_${title}":
            command => $nrpe_command,
            before  => ::Monitor_service[$title],
        }
    }

    # TODO: Refactor this to make a call to nagios::monitor_service (or similar) after nagios
    # has been refactored to a module. It is known to cause rspec tests to fail
    ::monitor_service { $title:
        ensure        => $ensure,
        description   => $description,
        check_command => "nrpe_check!check_${title}",
        contact_group => $contact_group,
        retries       => $retries,
    }
}
