# == Class: cassandra::reporter
#
# Class used for the configuration of reporters and setting up the log
# directory.
#
# === Parameters
#
# [*logstash_es_host*]
#   The ElasticSearch server hosting the logs.
#   Default: 'logstash1001.eqiad.wmnet'
#
# [*logstash_es_port*]
#   The port ES is listening on. Default: 9200
#
# [*log_dir*]
#   The log directory where to write the output of the reporting scripts.
#   The directory is created if it does not exist.
#   Default: '/var/log/cassandra-reports'
#
class cassandra::reporter(
    $logstash_es_host = 'logstash1001.eqiad.wmnet',
    $logstash_es_port = 9200,
    $log_dir          = '/var/log/cassandra-reports',
) {

    file { $log_dir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

}
