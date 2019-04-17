# == Class role::aqs
# Analytics Query Service
#
# AQS is made up of a RESTBase instance backed by Cassandra.
# Each AQS node has both colocated.
#
# filtertags: labs-project-deployment-prep
class role::aqs::canary {
    system::role { 'aqs::canary':
        description => '***Canary Server***',
    }
    include ::role::aqs
}
