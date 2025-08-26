# The 'nova compute' service does the actual VM management
#  within nova.
# https://wiki.openstack.org/wiki/Nova
class openstack::nova::compute::monitor(
    $active,
    $verify_instances=false,
    $contact_groups='wmcs-bots,admins',
){

    # monitoring::service doesn't take a bool
    if $active {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    if ($active) and ($verify_instances) {

        $kvmbinary = 'qemu-system-x86_64'

        # Where a stopped nova-compute processes means we are no longer processing
        # control plane messaging above, this check makes sure that at least one (even
        # if it is a token administrative) instance is running.  If a hypervisor
        # does reboot it will come up without running instances even after the nova-compute
        # processes has been fully restored.

        # This means we need to have a token administrative instance running on all
        # active hypervisors as a canary:
        # OS_PROJECT_ID=testlabs openstack server create \
        # --flavor 2 --image <image-id> --availability-zone host:<hypervisor> <instance>
        nrpe::monitor_service { 'ensure_running_kvm_instances':
            ensure         => $ensure,
            description    => 'ensure kvm processes are running',
            nrpe_command   => "/usr/lib/nagios/plugins/check_procs -c 1:120 --ereg-argument-array ${kvmbinary}",
            retries        => 2,
            contact_group  => $contact_groups,
            notes_url      => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
            migration_task => 'T328502',
        }
    }
}
