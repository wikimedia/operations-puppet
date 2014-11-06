# == Class role::restbase
#

# Labs test role
# Config should be pulled from hiera
class role::restbase::labs (
    $cassandra_user     = 'cassandra',
    $cassandra_password = 'cassandra',
    $cassandra_defaultConsistency = 'localQuorum',
    $logstash_host      = 'deployment-logstash1.eqiad.wmflabs',
    $logstash_port      = 12201,
    $seeds              = [ 'localhost' ],
) {
    system::role { 'restbase': description => 'restbase labs' }

    class { '::restbase':
        cassandra_user      => $cassandra_user,
        cassandra_password  => $cassandra_password,
        cassandra_defaultConsistency => $cassandra_defaultConsistency,
        logstash_host       => $logstash_host,
        logstash_port       => $logstash_port,
        seeds               => $seeds,
    }
}
