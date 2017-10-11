# TODO: Revisit the is_critical part. We probably want pages for DB problems for
# at least a group of people
class mariadb::monitor_process(
    $is_critical    = true,
    $contact_group  = 'dba',
    $process_name   = 'mysqld',
    $process_count  = 1,
    ) {

    # is_critical means "paging on/off" in this context, not the Icinga status
    # certain host names are excluded from ever creating pages (T178008)
    if $::fqdn =~ /^labtest/ {
        $paging = false
    } else {
        $paging = $is_critical
    }

    nrpe::monitor_service { $process_name:
        description   => "${process_name} processes",
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c ${process_count}:${process_count} -C ${process_name}",
        critical      => $paging,
        contact_group => $contact_group,
    }
}
