# == Class confluent::kafka::common
#
# Installs the confluent-kafka package and a handy kafka wrapper script.
#
# Most likely you will not use this class directly, and instead
# just use confluent::kafka::broker to install and start a Kafka broker.
# You will only use confluent::kafka::common directly if you need to
# change the version of java, kafka, or scala that is being installed, or if
# you want to install the confluent-kafka package without puppet managing
# a Kafka broker.
#
# == Parameters
#
# [*java_home*]
#   Path to JAVA_HOME.  This class does not manage installation of Java.
#   You must do that elsewhere.  Default: undef (will use system default).
#
# [*kafka_version*]
#   Ensure this version of a confluent-kafka package is installed.
#   Default: undef
#
# [*scala_version*]
#   Package confluent-kafka-$scala_version will be installed.
#   Default: 2.11
#
class confluent::kafka::common(
    $java_home     = undef,
    $kafka_version = undef,
    $scala_version = '2.11'
) {
    $package = "confluent-kafka-${scala_version}"

    apt::repository { 'thirdparty-confluent':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => 'thirdparty/confluent',
    }

    # If $kafka_version was given,
    # make sure that a specific debian package version was installed.
    if !$kafka_version {
        package { $package:
            require => [ Apt::Repository['thirdparty-confluent'], Exec['apt-get update']],
        }
    }
    else {
        package { $package:
            ensure  => $kafka_version,
            require => [ Apt::Repository['thirdparty-confluent'], Exec['apt-get update']],
        }
    }

    # TODO: Remove this conditional after Kafka has been upgraded everywhere in T167039.
    # Once we are on a confluent package with $scala_version == 2.11, we know that
    # we will be using a package that installs systemd units.
    if $scala_version == '2.11' {
        # Ensure that the confluent systemd units are disabled.  The confluent-kafka
        # package installs these, and we don't want to remove their .service files
        # in case it would cause package conflicts during future upgrades, so we just
        # ensure they are not running and masked in systemd.
        #
        # work around "Error: Could not set 'mask' on enable:undefined method `mask' for Service"
        # that occurs on Jessie hosts by forcing provider => 'systemd'
        service { ['confluent-kafka', 'confluent-kafka-connect', 'confluent-zookeeper']:
            ensure   => 'stopped',
            enable   => 'mask',
            provider => 'systemd',
            require  => Package[$package],
        }
    }

    group { 'kafka':
        ensure  => 'present',
        system  => true,
        require => Package[$package],
    }
    # Kafka system user
    user { 'kafka':
        gid        => 'kafka',
        shell      => '/bin/false',
        home       => '/nonexistent',
        comment    => 'Apache Kafka',
        system     => true,
        managehome => false,
        require    => Group['kafka'],
    }

    file { '/var/log/kafka':
        ensure => 'directory',
        owner  => 'kafka',
        group  => 'kafka',
        mode   => '0755',
    }

    file { '/usr/local/bin/kafka':
        source  => 'puppet:///modules/confluent/kafka/kafka.sh',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package[$package],
    }

    # Have puppet manage totally manage this directory.
    # Anything it doesn't know about will be removed.
    file { '/etc/kafka/mirror':
        ensure  => 'directory',
        owner   => 'kafka',
        group   => 'kafka',
        recurse => true,
        purge   => true,
        force   => true,
        require => Package[$package],
    }
}
