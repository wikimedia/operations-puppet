# The 'nova compute' service does the actual VM management
#  within nova.
# https://wiki.openstack.org/wiki/Nova
class openstack2::nova::compute::monitor(
    $active,
    $certname,
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
        ensure       => $ensure,
        description  => 'kvm ssl cert',
        nrpe_command => "/usr/local/lib/nagios/plugins/check_ssl_certfile /etc/ssl/localcerts/${certname}.crt",
    }

    # The weird [n] is an attempt to keep check_procs from counting itself.
    #  https://serverfault.com/questions/359958/nagios-nrpe-check-procs-wrong-return-value
    nrpe::monitor_service { 'check_nova_compute_process':
        ensure       => $ensure,
        description  => 'nova-compute process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 --ereg-argument-array '^/usr/bin/pytho[n] /usr/bin/nova-compute'",
        retries      => 5,
    }
}
