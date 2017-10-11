# TODO: Revisit the is_critical part. We probably want pages for DB problems for
# at least a group of people
class mariadb::monitor_process(
    $is_critical    = true,
    $contact_group  = 'dba',
    $process_name   = 'mysqld',
    $process_count  = 1,
    ) {

    if $::fqdn =~ /^labtest/ {
        $paging = false
    } else {
        $paging = true
    }

    nrpe::monitor_service { $process_name:
        description   => "${process_name} processes",
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c ${process_count}:${process_count} -C ${process_name}",
        critical      => $paging,
        contact_group => $contact_group,
    }
}
