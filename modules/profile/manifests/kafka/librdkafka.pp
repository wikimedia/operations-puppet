# Packages required by Kafka clients
class profile::kafka::librdkafka() {

    service::packages { 'librdkafka':
        pkgs     => ['librdkafka++1', 'librdkafka1'],
        dev_pkgs => ['librdkafka-dev'],
    }

}
