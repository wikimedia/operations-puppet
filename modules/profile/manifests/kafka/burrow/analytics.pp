# == class profile::kafka::burrow::analytics
#
# Consumer offset lag monitoring tool for the Kafka Analytics cluster
#
class profile::kafka::burrow::analytics(
    $consumer_groups = hiera('profile::kafka::burrow:analytics::consumer_groups'),
    $to_emails       = hiera('profile::kafka::burrow:analytics::to_emails', ['analytics-alerts@wikimedia.org'])
) {

    profile::kafka::burrow { 'analytics':
        consumer_groups => $consumer_groups,
        http_port       => 8000,
        to_emails       => $to_emails,
    }
}
