# = Class: profile::mjolnir::kafka_daemon
#
# This class sets up the MjoLniR kafka daemon which facilitates running
# elasticsearch queries against relforge from the analytics network by using
# kafka as a middleman.
#
class profile::mjolnir::kafka_daemon(
    # This is the analytics kafka cluster. For historical reasons
    # it is named just 'eqiad'.
    $kafka_config = kafka_config('eqiad'),
) {
    scap::target { 'relforge/mjolnir':
      deploy_user => 'deploy-service',
    }

    # This is a limited subset of what the full mjolnir package requires because
    # the daemon is a small part of the overall application. The daemon only needs
    # to read/write kafka topics and send requests to localhost.
    require_package('python-kafka', 'python-requests')

    systemd::service { 'mjolnir-kafka-daemon':
        content => template('profile/mjolnir/kafka-daemon.service.erb'),
        require  => Scap::Target['relforge/mjolnir'],
    }

}
