# kafka-puppet

A Puppet module for installing and managing Apache Kafka brokers.
This module is maintained at https://github.com/wikimedia/puppet-kafka.


## Requirements:
- Java
- An installable Apache Kafka package.  You can use one available at
[the Wikimedia apt repository](http://apt.wikimedia.org/wikimedia/pool/universe/k/kafka/),
or build your own using [operations/debs/kakfa](https://gerrit.wikimedia.org/r/gitweb?p=operations/debs/kafka.git;a=summary).

## Usage:
```puppet
# install the kafka pacakge and configure kafka.
class { "kafka":
  zookeeper_hosts => ["zk1:2181", "zk2:2181", "zk3:2181"],
}


# start a kafka broker
class { "kafka::server":
    log_dir => "/var/lib/kafka",
}
```

If you do not set ```broker_id``` on kafka::server, the broker_id will be
inferred from integers in the node's hostname.  E.g. kafka01 will render
```server.properties``` with ```brokerid``` == 1.
