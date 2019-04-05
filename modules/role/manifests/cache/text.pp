# filtertags: labs-project-deployment-prep
class role::cache::text {

    system::role { 'cache::text':
        description => 'text Varnish cache server',
    }
    include ::standard
    include ::profile::cache::base
    include ::profile::cache::varnish::backend
    include ::profile::cache::ssl::unified
    include ::profile::cache::ssl::wikibase
    include ::profile::cache::text

    # varnishkafka statsv listens for special stats related requests
    # and sends them to the 'statsv' topic in Kafka. A kafka consumer
    # (called 'statsv') then consumes these and emits metrics.
    include ::profile::cache::kafka::statsv

    # varnishkafka eventlogging listens for eventlogging beacon
    # requests and logs them to the eventlogging-client-side
    # topic.  EventLogging servers consume and process this
    # topic into many JSON based kafka topics for further
    # consumption.
    include ::profile::cache::kafka::eventlogging

    # TODO: refactor all this so that we have separate roles for production and labs
    if $::realm == 'production' and $::hostname != 'cp1008' {
        include ::role::ipsec
    }
}
