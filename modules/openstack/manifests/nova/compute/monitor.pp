# The 'nova compute' service does the actual VM management
#  within nova.
# https://wiki.openstack.org/wiki/Nova
class openstack::nova::compute::monitor(
    $active,
    $certname,
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

    file { '/usr/local/lib/nagios/plugins/check_ssl_certfile':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/nagios_common/check_commands/check_ssl_certfile',
    }

    # T116332
    nrpe::monitor_service { 'kvm_ssl_cert':
        ensure        => $ensure,
        description   => 'kvm ssl cert',
        nrpe_command  => "/usr/local/lib/nagios/plugins/check_ssl_certfile /etc/ssl/localcerts/${certname}.crt",
        contact_group => $contact_groups,
    }

    # Having multiple nova-compute process running long term has been known to happen
    # when puppet staggers a restart and nova gets very confused with dualing processes
    # pulling from rabbimq and potentially executing conflicting instructions.  A transient
    # value of 2 process can be fine during graceful restart though so ensure only 1 but
    # give a generous allowance for recheck.
    #
    # The weird [n] is an attempt to keep check_procs from counting itself.
    #  https://serverfault.com/questions/359958/nagios-nrpe-check-procs-wrong-return-value
    nrpe::monitor_service { 'ensure_single_nova_compute_proc':
        ensure        => $ensure,
        description   => 'nova-compute proc maximum',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1:1 --ereg-argument-array '^/usr/bin/pytho[n] /usr/bin/nova-compute'",
        retries       => 5,
        contact_group => $contact_groups,
    }

    # Labvirts have been known to fully reboot in <=4 minutes and
    # instances /do not/ come up as started automatically so we need
    # to alert on an unreachable/down nova-compute process fairly quickly.
    # But allow for the possibility of 2 procs in case it is in graceful
    # transition where this persistent bad state will alert above.
    nrpe::monitor_service { 'ensure_nova_compute_running':
        ensure        => $ensure,
        description   => 'nova-compute proc minimum',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1:2 --ereg-argument-array '^/usr/bin/pytho[n] /usr/bin/nova-compute'",
        retries       => 1,
        contact_group => $contact_groups,
    }

    if ($active) and ($verify_instances) {

        if os_version('ubuntu trusty') {
            $kvmbinary = '/usr/bin/kvm'
        } else {
            $kvmbinary = 'qemu-system-x86_64'
        }

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
            ensure        => $ensure,
            description   => 'ensure kvm processes are running',
            nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1:120 --ereg-argument-array ${kvmbinary}",
            retries       => 2,
            contact_group => $contact_groups,
        }
    }
}
