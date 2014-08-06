class hhvm::monitoring (
    $is_critical   = true,
    $contact_group = 'hhvm',
    $process_count = 1,
    ) {

    nrpe::monitor_service { 'hhvm':
        description   => 'HHVM processes',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c ${process_count}:{$process_count} -C hhvm",
        critical      => $is_critical,
        contact_group => $contact_group,
    }

}
