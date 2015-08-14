# == Class role::analytics::restbase
# This is a copy of role::restbase, and it exists so that a separate RESTBase cluster
#   can be set up with separate hieradata-provided parameter values.  For more info
#   on parameters, check out ../restbase.pp
#
@monitoring::group { 'restbase_analytics_eqiad': description => 'Analytics Restbase eqiad' }
@monitoring::group { 'restbase_analytics_codfw': description => 'Analytics Restbase codfw' }

# Config should be pulled from hiera
class role::analytics::restbase {
    system::role { 'restbase-analytics': description => "Analytics Restbase ${::realm}" }

    include ::restbase
    include ::restbase::monitoring

    include lvs::realserver


    ferm::service {'restbase_web':
        proto => 'tcp',
        port  => '7231',
    }

    /*
    TODO: add monitoring once we figure out what metrics we want
    monitoring::graphite_threshold { 'restbase_analytics_<<some-metric-name>>':
        description   => 'Analytics RESTBase req/s returning 5xx http://grafana.wikimedia.org/#/dashboard/db/restbase',
        metric        => '<<the metric and any transformations>>',
        from          => '10min',
        warning       => '<<warning threshold>>', # <<explain>>
        critical      => '<<critical threshold>>', # <<explain>>
        percentage    => '20',
        contact_group => 'analytics',
    }
    */
}
