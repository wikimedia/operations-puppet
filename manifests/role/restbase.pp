# == Class role::restbase
#

# Config should be pulled from hiera
class role::restbase {
    system::role { 'restbase': description => "Restbase ${::realm}" }

    include ::restbase

    # Emit an Icinga alert unless there is exactly one Java process belonging
    # to user 'cassandra' and with 'CassandraDaemon' in its argument list.
    nrpe::monitor_service { 'cassandra':
        description  => 'Cassandra database',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u cassandra -C java -a CassandraDaemon',
        require      => Service['cassandra'],
        critical     => 'true',
    }
}
