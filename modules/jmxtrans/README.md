# puppet-jmxtrans

A Puppet module for [jmxtrans](https://github.com/jmxtrans/jmxtrans).

This module assumes that a 'jmxtrans' package is available for
puppet to install.  You can download one from http://central.maven.org/maven2/org/jmxtrans/jmxtrans/.

Use the ```jmxtrans::metrics``` define to install
jmxtrans JSON query config files.  See the [jmxtrans wiki](https://github.com/jmxtrans/jmxtrans/wiki/Queries)
if you are not familiar with jmxtrans queries.

```jmxtrans::metrics``` abstracts much of the repetitive JSON structures
needed to build jmxtrans queries.  It currently supports KeyOutWriter,
GangliaWriter and GraphiteWriter.  You specify the JMX connection info
and the queries, and configuration information about each output writer
you would like to use.  You should use a single ```jmxtrans::metrics```
define for each JVM you would like query.  This will keep JMX queries
to a single JVM bundled together.  See jmxtrans
[best practices](https://github.com/jmxtrans/jmxtrans/wiki/BestPractices)
for more information.

The ```objects``` parameter to jmxtrans::metrics is an array of hashes of the form:

```puppet
objects => [
    {
        'name'        => 'JMX.object.name',
        'resultAlias' => 'pretty alias for JMX name', # optional
        'typeNames'   => ['name'], # optional
        # attrs is a hash of JMX attributes under this JMX object
        # with settings specific to this attribute.
        # Most settings will only be relevant to specific output writers.
        # Each available option is described here:
        'attrs'       => {
            'JMX.attribute.name' => {
                # Ganglia Options.  See:
                # https://github.com/jmxtrans/jmxtrans/wiki/GangliaWriter#example-configuration

                # Slope must be one of ```both```, ```positive```, or ```negative```.
                # See http://codeblog.majakorpi.net/post/16281432462/ganglia-xml-slope-attribute
                'slope'       => 'both|positive|negative',
                'units'       => 'unit name',
                'tmax'        => 'seconds value',
                'dmax'        => 'seconds value',
                'sendMetadata => 'frequency value',
            }
        }
    }
]
```
Notes:

- Yes, the hash after attribute name could be empty.
- No, we don't support replacing it with an array of names.

# Usage Examples

## Hadoop NameNode with multiple jmxtrans outputs

Query a Hadoop NameNode for some stats, and write the metrics to
/tmp/namenode.jmx.out, Ganglia, and Graphite.

```puppet
jmxtrans::metrics { 'hadoop-hdfs-namenode':
    jmx                   => '127.0.0.1:9980',
    outfile               => '/tmp/namenode.jmx.out',
    ganglia               => '127.0.0.1:8649',
    ganglia_group_name    => 'hadoop',
    graphite              => '127.0.0.1:2003',
    graphite_root_prefix  => 'hadoop',
    objects              => [
        {
            'name'           =>  'Hadoop:service=NameNode,name=NameNodeActivity',
            'resultAlias'    => 'hadoop.namenode',
            'attrs'          => {
                'FileInfoOps'  => { 'units' => 'operations', 'slope' => 'positive' },
                'FilesCreated' => { 'units' => 'creations',  'slope' => 'positive' },
                'FilesDeleted' => { 'units' => 'deletions',  'slope' => 'positive' },
            }
        },
        {
            'name' => 'Hadoop:service=NameNode,name=FSNamesystem',
            'attrs => {
                'BlockCapacity' => { 'units' => 'blocks', 'slope' => 'both' },
                'BlocksTotal'   => { 'units' => 'blocks', 'slope' => 'both' },
                'TotalFiles'    => { 'units' => 'files',  'slope' => 'both' },
            }
        },
    ],
}
```

## Kafka Broker with jmxtrans Ganglia output

```puppet
include jmxtrans

# Since we have multiple hosts sharing the same objects,
# we define a $jmx_kafka_objects variable to hold them.
# This will be passed as the objects parameter to each Kafka host.

$jmx_kafka_objects = [
    {
        'name'   => 'kafka:type=kafka.BrokerAllTopicStat',
        'attrs   => {
            'BytesIn'              => { 'units' => 'bytes',    'slope' => 'positive' },
            'BytesOut'             => { 'units' => 'bytes',    'slope' => 'positive' },
            'FailedFetchRequest'   => { 'units' => 'requests', 'slope' => 'positive' },
            'FailedProduceRequest' => { 'units' => 'requests', 'slope' => 'positive' },
            'MessagesIn'           => { 'units' => 'messages', 'slope' => 'positive' }
        }
    },
    {
        'name'   => 'kafka:type=kafka.LogFlushStats',
        'attrs'  => {
            'FlushesPerSecond' => { 'units' => 'flushes' }, # 'both' is ganglia default slope value. Leaving it off here.
            'NumFlushes'       => { 'units' => 'flushes', 'slope' => 'positive' },
            'AvgFlushMs'       => { 'units' => 'ms' },
            'MaxFlushMs'       => { 'units' => 'ms' },
            'TotalFlushMs'     => { 'units' => 'ms', 'slope' => 'positive' }
        }
    },
    {
        'name'   => 'kafka:type=kafka.SocketServerStats',
        'attrs'  => {
            'BytesReadPerSecond'       => { 'units' => 'bytes' },
            'BytesWrittenPerSecond'    => { 'units' => 'bytes' },

            'ProduceRequestsPerSecond' => { 'units' => 'requests' },
            'AvgProduceRequestMs'      => { 'units' => 'requests' },
            'MaxProduceRequestMs'      => { 'units' => 'requests' },
            'TotalProduceRequestMs'    => { 'units' => 'ms' },

            'FetchRequestsPerSecond'   => { 'units' => 'requests' },
            'AvgFetchRequestMs'        => { 'units' => 'ms' },
            'MaxFetchRequestMs'        => { 'units' => 'ms' },
            'TotalFetchRequestMs'      => { 'units' => 'ms' }
        }
    }

]

# query kafka1 broker for its JMX metrics
jmxtrans::metrics { 'kafka1':
    jmx     => 'kafka1:9999',
    ganglia => '192.168.10.50:8469',
    objects => $jmx_kafka_objects,
}

# query kafka2 broker for its JMX metrics
jmxtrans::metrics { 'kafka2':
    jmx     => 'kafka2:9999',
    ganglia => '192.168.10.50:8469',
    objects => $jmx_kafka_objects,
}
```
