# = Class: profile::mjolnir::kafka_daemon
#
# This class sets up the MjoLniR kafka daemon which facilitates running
# elasticsearch queries against relforge from the analytics network by using
# kafka as a middleman.
#
class profile::mjolnir::kafka_msearch_daemon(
  $es_cluster_endpoint = lookup('profile::mjolnir::kafka_msearch_daemon::es_cluster_nedpoint', { 'default_value' => 'localhost:9200' }),
  $kafka_cluster = lookup('profile::mjolnir::kafka_msearch_daemon::kafka_cluster'),
  String $input_topic = lookup('profile::mjolnir::kafka_msearch_daemon::input_topic'),
  String $output_topic = lookup('profile::mjolnir::kafka_msearch_daemon::output_topic'),
  Integer $num_workers = lookup('profile::mjolnir::kafka_msearch_daemon::num_workers'),
  Integer $max_concurrent_searches = lookup('profile::mjolnir::kafka_msearch_daemon::max_concurrent_searches'),
  Integer $num_running_daemons = lookup('profile::mjolnir::kafka_msearch_daemon::num_running_daemons'),
  Array[String] $prometheus_nodes = lookup('prometheus_nodes',  {'default_value' => []}),
  Wmflib::Ensure $ensure = lookup('profile::mjolnir::kafka_msearch_daemon::ensure', { 'default_value' => 'present' }),
) {

    require ::profile::mjolnir

    $kafka_config = kafka_config($kafka_cluster)
    $prometheus_port = 9171
    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')

    # clear out the previous service
    ::systemd::service { 'mjolnir-kafka-msearch-daemon':
      ensure  => 'absent',
      content => template('profile/mjolnir/kafka-msearch-daemon.service.erb'),
    }
    ::base::service_auto_restart { 'mjolnir-kafka-msearch-daemon':
      ensure => 'absent',
    }

    systemd::unit { 'mjolnir-kafka-msearch-daemon@.service':
      ensure  => $ensure,
      content => template('profile/mjolnir/kafka-msearch-daemon@.service.erb'),
    }

    range('0', $num_running_daemons - 1).each |$i| {
      $title = String($i)
      profile::mjolnir::kafka_msearch_daemon_instance { $title:
        ensure                => $ensure,
        prometheus_port       => $prometheus_port + $i,
        prometheus_nodes_ferm => $prometheus_nodes_ferm,
      }
    }
}
