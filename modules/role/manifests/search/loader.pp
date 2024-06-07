# Role class for airflow
#
class role::search::loader {
    include profile::base::production
    include profile::firewall

    include profile::mjolnir::kafka_bulk_daemon
    include profile::mjolnir::kafka_msearch_daemon
}
