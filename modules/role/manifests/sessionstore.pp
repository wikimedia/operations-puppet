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
    include ::profile::cassandra
    # FIXME - temp fix for T219560 - will move to profile asap
    include ::passwords::cassandra # lint:ignore:wmf_styleguide

}
