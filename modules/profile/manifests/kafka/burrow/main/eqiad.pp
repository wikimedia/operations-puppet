# == class profile::kafka::burrow::main::eqiad
#
# Consumer offset lag monitoring tool for the Kafka Main eqiad cluster
#
class profile::kafka::burrow::main::eqiad {

    profile::kafka::burrow { 'main-eqiad':
        http_port       => 8100,
    }
}
