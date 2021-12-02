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
# [*scala_version*]
#   Package confluent-kafka-$scala_version will be installed.
#   Default: 2.11
#
class confluent::kafka::common(
    $java_home     = undef,
    $scala_version = '2.11',
    $user_group_id = undef,
) {
    $package = "confluent-kafka-${scala_version}"

    apt::package_from_component { 'confluent-kafka':
        component => 'thirdparty/confluent',
        packages  => [$package],
    }

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

    group { 'kafka':
        ensure  => 'present',
        gid     => $user_group_id,
        system  => true,
        require => Package[$package],
    }
    # Kafka system user
    user { 'kafka':
        gid        => 'kafka',
        uid        => $user_group_id,
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
