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
    class { 'mjolnir': }

    systemd::service { 'mjolnir-kafka-daemon':
        content => template('profile/mjolnir/kafka-daemon.service.erb'),
        require => Class['mjolnir'],
    }

}
