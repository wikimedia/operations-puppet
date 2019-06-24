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
mulitple MirrorMaker instance.  The `confluent::kafka::mirror::instance` is
used for this.  However, it may be easier to specify the MirrorMaker instance
configuration in Hiera rather than in Puppet.  For this, the
`confluent::kafka::mirrors` class can be used.  It takes a hash of
`$mirrors` configuration and declares each mirror instance via the
Puppet `create_resources` function.

```
# Set up mirror instances to mirror both Kafka clusters mainA and mainB
# to an aggregate cluster.  Note that if you are running multiple
# mirror instances on a single host, you must specify unique
# jmx_ports for each of them.
class { 'confluent::kafka::mirrors:
 $mirrors => {
     'mainA_to_aggregate' => {
         'source_zookeeper_url' => 'zk1:2181/kafka/mainA'
         'jmx_port'             => 9995,
     },
     'mainB_to_aggregate' => {
         'source_zookeeper_url' => 'zk1:2181/kafka/mainB'
         'jmx_port'             => 9994,
     },
 },
 mirror_defaults => {
     'destination_brokers' => 'agg1:9092,agg2:9092'
     'whitelist'           => 'my_topics\..+',
     'num_streams'         => 2,
 }
}
```

See the documentation for `confluent::kafka::mirror::instance` and
`confluent::kafka::mirrors` for more information.
