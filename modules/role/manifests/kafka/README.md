# Role classes for configuring Kafka Clusters

Each role consists of a config class and a broker class.

The config classes will contain only variable definitions, so they are safe to
include and use anywhere, e.g. for configuring Kakfa clients.

The broker classes will include their respective config classes, and set up
a Kafka broker belong to a specific cluster.

Each config class is configurable via 2 hiera variables:

##### `kafka_cluster_name`
This string identifies the kafka cluster in the `kafka_cluster_config`, as well
as determining the zookeeper chroot in which Kafka will store its metadata.
If not found in hiera, this will default to something intelligent in labs
and in production that makes sense for the role.  This hiera variable is
specific to a node including the role classes, so it is safe to override
this at a more specific hiera level than common.yaml.

##### `kafka_clusters`
This hash should contain configuration for all known Kafka clusters.  As such,
it should live in a top level hiera file, likely common.yaml.  Individual
kafka cluster configs can be accessed in this hash by name.

It should be of the form:

```yaml
kafka_clusters:
  clusterA-eqiad:
    brokers:
      kafka1.eqiad.wmnet:
        id: 1
      kafka2.eqiad.wmnet:
        id: 2
        port: 9093
  clusterB-eqiad:
    brokers:
      kafka300.eqiad.wmnet:
        id: 300
      kafka301.eqiad.wmnet:
        id: 301
        port: 9093
 # etc...
```

Each key in `kafka_clusters` is a cluster name.  This name will be used
for the zookeeper chroot.  If not found in hiera, this variable will default to:

```yaml
$kafka_cluster_name:
  brokers:
    $::fqdn:
      id: 1
```

This allows you to easily stand up a single node kafka 'cluster' in labs without
having any hiera configs set.

