# filtertags: labs-project-deployment-prep
class role::cache::text {

    system::role { 'cache::text':
        description => 'text Varnish cache server',
    }
    include ::standard
    include ::profile::cache::base
    include ::profile::cache::ssl::unified
    include ::profile::cache::text

    # varnishkafka statsv listens for special stats related requests
    # and sends them to the 'statsv' topic in Kafka. A kafka consumer
    # (called 'statsv') then consumes these and emits metrics.
    include ::profile::cache::kafka::statsv

    # TODO: refactor all this so that we have separate roles for production and labs
    if $::realm == 'production' {
        include ::role::ipsec
    }
}
