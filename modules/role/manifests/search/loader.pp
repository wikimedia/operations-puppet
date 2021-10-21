# Role class for airflow
#
class role::search::loader {
    system::role { 'search::loader':
        description => 'Search models loader for ElasticSearch',
    }

    include ::profile::base::production
    include ::profile::base::firewall

    include ::profile::mjolnir::kafka_bulk_daemon
    include ::profile::mjolnir::kafka_msearch_daemon
}
