<!-- SPDX-License-Identifier: Apache-2.0 -->
# Profile classes for configuring Kafka


## Global Hiera variables

Aside from the profile level variables that are documented in the profile::kafka::broker class,
3 top level hiera variables are important.

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
    zookeeper_cluster_name: zkclusterA-eqiad
    brokers:
      kafka1001.eqiad.wmnet:
        id: 1001
      kafka1002.eqiad.wmnet:
        id: 1002
        port: 9093
  clusterB-codfw:
    zookeeper_cluster_name: zkclusterA-codfw
    brokers:
      kafka2001.codfw.wmnet:
        id: 2001
      kafka2002.codfw.wmnet:
        id: 2002
        port: 9093
 # etc...
```

Each key in `kafka_clusters` is a cluster name.  This name will be used
for the zookeeper chroot.  zookeeper_cluster_name should be a key in another
top level hiera variable `zookeeper_clusters`.  The zookeeper hostnames
for `zookeeper_cluster_name` are looked up in `zookeeper_clusters` config
and provided to Kafka configuration properties.

##### `zookeeper_clusters`
This hash is similar to the `kafka_clusters` one, except that it contains
configuration information for zookeeper, rather than Kafka.  The `zookeeper_clusters`
hash should be keyed by zookeeper cluster names, and a key corresponding
to each `zookeeper_cluster_name` in `kafka_clusters` should exist and specific
the zookeeper hosts in that cluster.
