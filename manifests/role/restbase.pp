# == Class role::restbase
#

class role::restbase::labs::otto_cass {
    system::role { 'restbase': description => 'restbase labs::otto_cass' }

    class { '::restbase':
        cassandra_user     => 'test', # $::passwords::cassandra::otto-cass::user,
        cassandra_password => 'test', # $::passwords::cassandra::otto-cass::password,
        logstash_host      => 'deployment-logstash1.eqiad.wmflabs',
        logstash_port      => 12201,
        seeds              => [
            '10.68.17.68',
            '10.68.17.60',
            '10.68.17.71',
        ],
    }
}
