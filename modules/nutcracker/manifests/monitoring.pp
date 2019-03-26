# == Class: nutcracker::monitoring
#
# Provisions Icinga alerts for nutcracker.
#
class nutcracker::monitoring($port = 11212) {
    nrpe::monitor_service { 'nutcracker':
        description  => 'nutcracker process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u nutcracker -C nutcracker',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Nutcracker',
    }

    if ($port != 0) {
        nrpe::monitor_service { 'nutcracker_port':
            description  => 'nutcracker port',
            nrpe_command => "/usr/lib/nagios/plugins/check_tcp -H 127.0.0.1 -p ${port} --timeout=2",
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Nutcracker',
        }
    }
}
