# openstack scheduler determines on which host a
# particular instance should run
class openstack::nova::scheduler::monitor(
    $active,
    $critical=false,
    $contact_groups='wmcs-bots,admins',
){

    # monitoring::service doesn't take a bool
    if $active {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    nrpe::monitor_service { 'check_nova_scheduler_process':
        ensure        => $ensure,
        critical      => $critical,
        description   => 'nova-scheduler process',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/nova-scheduler'",
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }
}
