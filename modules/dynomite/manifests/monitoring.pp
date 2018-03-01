# == Class: dynomite::monitoring
#
# Provisions Icinga alerts for dynomite.
#
class dynomite::monitoring {
    nrpe::monitor_service { 'dynomite':
        description  => 'dynomite process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u dynomite -C dynomite',
    }
}