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

    include ::passwords::aqs

    include ::standard
    include ::base::firewall

    #
    # Set up Cassandra for AQS.
    #
    include ::profile::cassandra

    #
    # Set up AQS
    #

    include ::aqs
    include ::aqs::monitoring

    include role::lvs::realserver

    ferm::service {'aqs_web':
        proto => 'tcp',
        port  => $::aqs::port,
    }

    #TODO: add monitoring once we figure out what metrics we want
    #monitoring::graphite_threshold { 'restbase_analytics_<<some-metric-name>>':
        #description   => 'Analytics RESTBase req/s returning 5xx http://grafana.wikimedia.org/#/dashboard/db/restbase',
        #metric        => '<<the metric and any transformations>>',
        #from          => '10min',
        #warning       => '<<warning threshold>>', # <<explain>>
        #critical      => '<<critical threshold>>', # <<explain>>
        #percentage    => '20',
        #contact_group => 'aqs-admins',
    #}
}
