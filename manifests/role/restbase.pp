# == Class role::restbase
#

# Labs test role
class role::restbase::labs {
    system::role { 'restbase': description => 'restbase labs' }

    class { '::restbase':
        cassandra_user     => 'cassandra', # $::passwords::cassandra::otto-cass::user,
        cassandra_password => 'cassandra', # $::passwords::cassandra::otto-cass::password,
        cassandra_defaultConsistency => 'localQuorum',
        logstash_host      => 'deployment-logstash1.eqiad.wmflabs',
        logstash_port      => 12201,
        seeds              => [
            '10.68.17.68',
            '10.68.17.60',
            '10.68.17.71',
        ],
    }
}
