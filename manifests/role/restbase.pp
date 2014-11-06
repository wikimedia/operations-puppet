# == Class role::restbase
#

class role::restbase::labs::otto_cass {
    system::role{ 'restbase': description => 'restbase labs::otto_cass' }

    class { '::restbase':
        case $::realm {
            'labs': {
                seeds => ['10.68.17.68','10.68.17.60','10.68.17.71'],
                cassandra_user => 'test', # $::passwords::cassandra::otto-cass::user,
                cassandra_password => 'test', # $::passwords::cassandra::otto-cass::password,
            }
            #'production': {
            #    seeds => ['10.68.17.68','10.68.17.60','10.68.17.71'],
            #    cassandra_user => 'test', # $::passwords::cassandra::otto-cass::user,
            #    cassandra_password => 'test', # $::passwords::cassandra::otto-cass::password,
            #}
            default: {
                fail('unknown realm, should be labs or production')
            }
        }
    }
}
