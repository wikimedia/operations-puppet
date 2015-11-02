# == Class: logstash::output::elasticsearch::scripts
#
# Provision utility scripts for Logstash Elasticsearch output
#
class logstash::output::elasticsearch::scripts {
    file { '/usr/local/bin/logstash_delete_index.sh':
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/logstash/logstash_delete_index.sh',
    }

    file { '/usr/local/bin/logstash_decrease_replicas.sh':
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/logstash/logstash_decrease_replicas.sh',
    }

    file { '/usr/local/bin/logstash_optimize_index.sh':
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/logstash/logstash_optimize_index.sh',
    }

    file { '/usr/local/bin/logstash_clear_cache.sh':
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/logstash/logstash_clear_cache.sh',
    }
}
# vim:sw=4 ts=4 sts=4 et:
