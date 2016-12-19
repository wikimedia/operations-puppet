# == Class: cassandra::reporter::topk::bin
#
# Installs the topk partition reporter script.
#
# === Parameters
#
# [*fpath*]
#   The full path (including the file name) to the location of the script.
#   Default: ''
#
class cassandra::reporter::topk::bin(
    $fpath = '/usr/local/bin/cassandra-reporter-topk',
) {

    require_package('python-jsonschema', 'python-requests', 'python-jinja2')

    file { $fpath:
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/cassandra/reporter/topk.py',
    }

}
