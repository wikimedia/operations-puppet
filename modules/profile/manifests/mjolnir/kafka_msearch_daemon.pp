# = Class: profile::mjolnir::kafka_daemon
#
# This class sets up the MjoLniR kafka daemon which facilitates running
# elasticsearch queries against relforge from the analytics network by using
# kafka as a middleman.
#
class profile::mjolnir::kafka_msearch_daemon(
    $kafka_cluster = hiera('profile::mjolnir::kafka_msearch_daemon::kafka_cluster'),
    String $input_topic = hiera('profile::mjolnir::kafka_msearch_daemon::input_topic'),
    String $output_topic = hiera('profile::mjolnir::kafka_msearch_daemon::output_topic'),
    Integer $num_workers = hiera('profile::mjolnir::kafka_msearch_daemon::num_workers'),
    Integer $max_concurrent_searches = hiera('profile::mjolnir::kafka_msearch_daemon::max_concurrent_searches'),
) {
    require ::profile::mjolnir

    $kafka_config = kafka_config($kafka_cluster)
    ::systemd::service { 'mjolnir-kafka-msearch-daemon':
        content => template('profile/mjolnir/kafka-msearch-daemon.service.erb'),
    }

    ::base::service_auto_restart { 'mjolnir-kafka-msearch-daemon': }
}
