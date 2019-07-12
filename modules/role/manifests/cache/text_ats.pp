# filtertags: labs-project-deployment-prep
class role::cache::text_ats {
    system::role { 'cache::text_ats':
        description => 'text Varnish/ATS cache server',
    }
    include ::profile::standard
    include ::profile::cache::base
    include ::profile::cache::ssl::unified
    include ::profile::cache::ssl::wikibase
    include ::profile::cache::varnish::frontend
    include ::profile::cache::varnish::frontend::text
    include ::profile::trafficserver::backend

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
}
