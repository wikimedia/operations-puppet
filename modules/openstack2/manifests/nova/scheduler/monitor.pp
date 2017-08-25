# openstack scheduler determines on which host a
# particular instance should run
class openstack2::nova::scheduler::monitor(
    $active,
){

    # monitoring::service doesn't take a bool
    if $active {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    nrpe::monitor_service { 'check_nova_scheduler_process':
        ensure       => $ensure,
        description  => 'nova-scheduler process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/nova-scheduler'",
    }
}
