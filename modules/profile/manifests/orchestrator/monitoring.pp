# monitoring for mysql orchestrator - T266338
class profile::orchestrator::monitoring(
    Boolean $check_procs = lookup('profile::orchestrator::monitoring::check_procs', {'default_value' => false}),
    Boolean $check_tcp = lookup('profile::orchestrator::monitoring::check_tcp', {'default_value' => false}),
    Stdlib::Host $check_tcp_host = lookup('profile::orchestrator::monitoring::check_tcp_host', {'default_value' => '127.0.0.1'}),
    Stdlib::Port $check_tcp_port = lookup('profile::orchestrator::monitoring::check_tcp_port', {'default_value' => 3000}),
){

    $check_procs_ensure = $check_procs ? {
        true    => 'present',
        false   => 'absent',
        default => 'absent',
    }

    $check_tcp_ensure = $check_tcp ? {
        true    => 'present',
        false   => 'absent',
        default => 'absent',
    }

    nrpe::monitor_service { 'orchestrator_process':
        ensure       => $check_procs_ensure,
        description  => 'orchestrator process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 --ereg-argument-array 'orchestrator http'",
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Orchestrator',
    }

    nrpe::monitor_service { 'orchestrator_tcp_port':
        ensure       => $check_tcp_ensure,
        description  => 'orchestrator TCP port',
        nrpe_command => "/usr/lib/nagios/plugins/check_tcp -H ${check_tcp_host} -p ${check_tcp_port}",
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Orchestrator',
    }
}
