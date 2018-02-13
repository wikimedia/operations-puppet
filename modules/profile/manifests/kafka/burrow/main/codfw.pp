# == class profile::kafka::burrow::main::codfw
#
# Consumer offset lag monitoring tool for the Kafka Main codfw cluster
#
class profile::kafka::burrow::main::codfw {

    profile::kafka::burrow { 'main-codfw':
        http_port       => 8200,
    }
}
