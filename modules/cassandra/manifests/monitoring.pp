# == Class: cassandra::monitoring
#
# Configure monitoring reporting for cassandra
#
# === Usage
# class { '::cassandra::monitoring': }
#
# === Parameters
# [*contact_group*]
#   The nagios contact groups to use
#
# [*cql_port*]
#   The tcp port CQL is listening on
#
# [*heap_dump_directory*]
#   The directory to scan for heap dumps
#
# [*heap_dump_warning*]
#   How many heap dumps before a WARNING
#
# [*heap_dump_critical*]
#   How many heap dumps before a CRITICAL

class cassandra::monitoring(
    $contact_group = 'admins',
    $cql_port = 9042,
    $heap_dump_directory = '/var/lib/cassandra',
    $heap_dump_warning   = 3,
    $heap_dump_critical  = 10,
) {
    validate_string($contact_group)
    validate_re($cql_port, '^[0-9]+$')
    validate_string($heap_dump_directory)
    validate_re($heap_dump_warning, '^[0-9]+$')
    validate_re($heap_dump_critical, '^[0-9]+$')

    file { '/usr/local/lib/nagios/plugins/check_heapdump':
        source => "puppet:///modules/${module_name}/check_heapdump",
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # Check for heap dumps count T106346
    nrpe::monitor_service { 'cassandra_heapdumps':
        description   => 'cassandra JVM heapdumps present',
        nrpe_command  => "/usr/local/lib/nagios/plugins/check_heapdump --count-warning ${heap_dump_warning} --count-critical ${heap_dump_critical} ${heap_dump_directory}/\*.hprof",
        contact_group => $contact_group,
    }

    # Emit an Icinga alert unless there is exactly one Java process belonging
    # to user 'cassandra' and with 'CassandraDaemon' in its argument list.
    nrpe::monitor_service { 'cassandra':
        description   => 'Cassandra database',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u cassandra -C java -a CassandraDaemon',
        contact_group => $contact_group,
    }

    # CQL query interface monitoring (T93886)
    monitoring::service { 'cassandra-cql':
        description   => 'Cassanda CQL query interface',
        check_command => "check_tcp!${cql_port}",
        contact_group => $contact_group,
    }
}
