# Druid Puppet Module

This module works with the Druid debian packaging from.
https://gerrit.wikimedia.org/r/#/admin/projects/operations/debs/druid, and only
on systems with systemd.

Druid `common.runtime.properties` are configured via the main `druid`
init class.

Each Druid service is parameterized via the hashes `$properties` and
`$env`.  `$properties` will be rendered into
`/etc/druid/$service/runtime.properties`.  These will be picked up by
an individual Druid service. `$env` will be rendered into
`/etc/druid/$service/$env.sh`.  These shell environment variables will be
sourced by the systemd unit that starts the service.

## Druid with CDH
Druid ships with Hadoop dependencies.  As of Druid 0.9.0, these are
Hadoop 2.3.0. As of CDH 5.5, Cloudera ships with Hadoop 2.6.0.  In addition,
the versions of Jackson that ship with Druid are different than those that
ship with CDH.

This module contains class in the `druid::cdh::` namespace.  These classes
have a hard dependency on the [https://github.com/wikimedia/puppet-cdh](puppet-cdh)
module.  You cannot use these classes unless you have that already set up
and included.

First, you must ensure that the druid user exists on your Hadoop NameNodes,
and that druid HDFS directories are created.  The `druid::cdh::hadoop::setup`
class does this.  Include this class on your Hadoop NameNodes.  It will not
install the druid package, but it will ensure that a druid systemuser exists.

Druid must then be configured to use the CDH provided Hadoop Client
dependencies. This is done by setting $use_cdh = true on the main druid class.
This will include the `druid::cdh::hadoop::depdendencies`
class and create a new hadoop-dependency version of `cdh` and a new
`druid-hdfs-storage-cdh` extension.  Your Druid jobs must be configured with
`"hadoopDependencyCoordinates": ["org.apache.hadoop:hadoop-client:cdh"]`.

One more thing!  Snappy + Druid indexing does not seem to work properly!
Make sure you set

```
"jobProperties" : {"mapreduce.output.fileoutputformat.compress": "org.apache.hadoop.io.compress.GzipCodec"}
```

In your indexing task json, otherwise you will get errors like
```
java.lang.UnsatisfiedLinkError: org.apache.hadoop.util.NativeCodeLoader.buildSupportsSnappy()Z
```

and your indexing task will fail.
