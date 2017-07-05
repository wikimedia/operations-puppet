# = Class: role::elasticsearch::relforge
#
# This class sets up the MjoLniR kafka daemon which facilitates running
# elasticsearch queries against relforge from the analytics network by using
# kafka as a middleman.
#
class role::elasticsearch::mjolnir_kafka_daemon {
    scap::target { 'relforge/mjolnir':
      deploy_user => 'deploy-service',
    }

    require_package('python-kafka', 'python-requests')

    # This is the analytics kafka cluster. For historical reasons
    # it is named just 'eqiad'.
    $kafka_config = kafka_config('eqiad')

    file { '/etc/systemd/system/mjolnir-kafka-daemon.service':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        content => template('role/elasticsearch/mjolnir-kafka-daemon.service.erb'),
        before => Service['mjolnir-kafka-daemon']
    }

    service { 'mjolnir-kafka-daemon':
      ensure   => running,
      provider => systemd,
      enable   => true,
      require  => [
        Scap::Target['relforge/mjolnir'],
        File['/etc/systemd/system/mjolnir-kafka-daemon.service']
      ]
    }

}
