# kafka-puppet

A Puppet module for installing and managing Apache Kafka brokers.


## Requirements:
- Java
- An installable Apache Kafka package.  You can use the one available at
[kafka-debian](https://github.com/wmf-analytics/kafka-debian).

## Usage:
```puppet
# install the kafka package
include kafka

# include common config
class { "kafka::config":
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
