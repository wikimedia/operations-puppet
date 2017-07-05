# = Class: profile::mjolnir::kafka_daemon
#
# This class sets up the MjoLniR kafka daemon which facilitates running
# elasticsearch queries against relforge from the analytics network by using
# kafka as a middleman.
#
class profile::mjolnir::kafka_daemon(
    # This is the analytics kafka cluster. For historical reasons
    # it is named just 'eqiad'.
    kafka_config = kafka_config('eqiad')
) {
    scap::target { 'relforge/mjolnir':
      deploy_user => 'deploy-service',
    }

    # This is a limited subset of what the full mjolnir package requires because
    # the daemon is a small part of the overall application. The daemon only needs
    # to read/write kafka topics and send requests to localhost.
    require_package('python-kafka', 'python-requests')

    file { '/etc/systemd/system/mjolnir-kafka-daemon.service':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/mjolnir/kafka-daemon.service.erb'),
        before  => Service['mjolnir-kafka-daemon']
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
