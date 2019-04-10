# == Class role::sessionstore
#
# Configures the production session storage cluster
class role::sessionstore {

    system::role { 'sessionstore':
        description => 'Session storage service'
    }

    include ::profile::base::firewall
    include ::standard
    # include ::role::lvs::realserver
    include ::profile::sessionstore
    include ::profile::cassandra
}
