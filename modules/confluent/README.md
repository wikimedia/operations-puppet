# confluent puppet module
This module is used to install and run [Confluent](http://www.confluent.io/)
packages and daemons.

Daemon processes are all managed via systemd, and as such this module should
only be used with a system that supports systemd.

As of 2016-05, this module only contains puppetization of the Confluent
Kafka package and Kafka broker.

# Usage

## Kafka

```puppet

# Install and run a Kafka Broker
class { 'confluent::kafka::broker':
    brokers => {
        'brokerA' => {
            'id' => 1,
        }
        'brokerB' => {
            'id' => 2,
        }
    },
    zookeeper_connect => 'zk1:2181,zk2:2181,zk3:2181/kafka/mycluster',
    log_dirs          => ['/var/spool/kafka/a', '/var/spool/kafka/b'],
}

```

See `manifests/kafka/broker.pp` for class documentation.

Once a broker is installed, the CLI wrapper script at `/usr/local/bin/kafka`
can be used to ease using the various kafka shell script installed in
`/usr/bin/kafka-*`.  The `ZOOKEEPER_URL` and `BROKERS_LIST` environment
variables are set in user profiles by `/etc/profile.d/kafka.sh`.
`/usr/local/bin/kafka` automatically fills in `kafka-*` commands that require this
information. Example:

```bash
# --zookeeper-connect will be given from $ZOOKEEPER_URL
kafka console-producer --topic test
```

```bash
# --brokers-list will be given from $BROKER_LIST
kafka console-consumer --topic test
```
etc...

## Kafka MirrorMaker
Each MirrorMaker instance can be configured to consume from one Kafka cluster
and produce to one Kafka cluster.  If you want to mirror from multiple
source clusters into one aggregate cluster, you will need to set up
mulitple MirrorMaker instance.  The `confluent::kafka::mirror::instance` is used for this.

See the documentation for `confluent::kafka::mirror::instance` for more information.
