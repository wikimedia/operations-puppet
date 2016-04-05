# == Class role::analytics_cluster::hive::beeline
# Sets up a wrapper script for beeline, the commandline
# interface to HiveServer2 and installs it at
# /usr/local/bin/beeline
#
class role::analytics_cluster::hive::beeline {

    $hiveserver_host = hiera('cdh::hive::server_host', 'localhost')
    $hiveserver_port = hiera('cdh::hive::server_port', '10000')

    # Handy script to set up environment for commandline nova magic
    file { '/usr/local/bin/beeline':
        content => template('analytics_cluster/hive/beeline_wrapper.py.erb'),
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
    }
}
