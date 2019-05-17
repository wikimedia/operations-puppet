# == Class: mcrouter::monitoring
#
# Provisions Icinga alerts for mcrouter.
#
class mcrouter::monitoring {
    nrpe::monitor_service { 'mcrouter':
        description  => 'mcrouter process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u mcrouter -C mcrouter',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Mcrouter',
    }
}
