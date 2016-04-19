# == Class confluent::kafka::client
# Installs the confluent-kafka package and a handy kafka wrapper script
#
class confluent::kafka::client(
    $java_package  = 'openjdk-7-jdk',
    $scala_version = '2.11.7'
) {
    require_package($java_package)

    $package = "confluent-kafka-${scala_version}"
    require_package($package)

    file { '/usr/local/bin/kafka':
        source => 'puppet:///modules/confluent/kafka/kafka.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        require => [Package[$package], Package[$java_package]],
    }
}
