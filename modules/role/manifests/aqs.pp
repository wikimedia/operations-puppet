# == Class role::aqs
# Analytics Query Service
#
# AQS is made up of a RESTBase instance backed by Cassandra.
# Each AQS node has both colocated.
#
# filtertags: labs-project-deployment-prep
class role::aqs {
    system::role { 'aqs':
        description => 'Analytics Query Service Node',
    }

    include ::standard
    include ::profile::base::firewall

    require ::passwords::aqs
    include ::profile::cassandra
    include ::profile::aqs

    include role::lvs::realserver
}
