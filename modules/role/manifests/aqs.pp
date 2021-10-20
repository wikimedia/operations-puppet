# == Class role::aqs
# Analytics Query Service
#
# AQS is made up of a RESTBase instance backed by Cassandra.
# Each AQS node has both colocated.
#
class role::aqs {
    system::role { 'aqs':
        description => 'Analytics Query Service Node',
    }

    include ::profile::base::production
    include ::profile::base::firewall

    include ::profile::cassandra
    include ::profile::aqs

    include ::profile::rsyslog::udp_localhost_compat
    include profile::lvs::realserver
}
