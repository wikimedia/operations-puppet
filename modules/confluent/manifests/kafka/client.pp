# == Class confluent::kafka::client
#
# Installs the confluent-kafka package and a handy kafka wrapper script.
#
# Most likely you will not use this class directly, and instead
# just use confluent::kafka::broker to install and start a Kafka broker.
# You will only use confluent::kafka::client directly if you need to
# change the version of java or scala that is being installed, or if
# you want to install the confluent-kafka package without puppet managing
# a Kafka broker.
#
# == Parameters
#
# [*java_package*]
#   Name of java package to require.  This will be passed to require_package().
#   Default: openjdk-7-jdk
#
# [*scala_version*]
#   confluent-kafka-$scala_version will be installed.
#   Default: 2.11.7
#
class confluent::kafka::client(
    $java_package  = 'openjdk-7-jdk',
    $scala_version = '2.11.7'
) {
    $package = "confluent-kafka-${scala_version}"
    require_package([$java_package, $package])

    file { '/usr/local/bin/kafka':
        source  => 'puppet:///modules/confluent/kafka/kafka.sh',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => [
            Package[$java_package],
            Package[$package],
        ],
    }

    # Have puppet manage totally manage this directory.
    # Anything it doesn't know about will be removed.
    file { '/etc/kafka/mirror':
        ensure  => 'directory',
        recurse => true,
        purge   => true,
        force   => true,
    }
}
