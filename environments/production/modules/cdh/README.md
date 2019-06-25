# Description

Puppet module to install and manage components of
Cloudera's Distribution (CDH) for Apache Hadoop.

This repository works with CDH5.  For CDH4, use the ```cdh4``` branch.

NOTE: The main puppet-cdh repository is hosted in WMF Gerrit at
[operations/puppet/cdh](https://gerrit.wikimedia.org/r/#/admin/projects/operations/puppet/cdh).


Installs HDFS, YARN, Hive, Pig, Sqoop (1), Oozie and
Hue.  Note that, in order for this module to work, you will have to ensure
that:

- Java version 7 or greater is installed
- Your package manager is configured with a repository containing the
  Cloudera 5 packages.

**Notes:**

- In general, services managed by this module do not subscribe to their relevant
  config files.  This prevents accidental deployments of config changes.  If you
  make config changes in puppet, you must apply puppet and then manually restart
  the relevant services.
- This module has only been tested using CDH 5.0.1 on Ubuntu Precise 12.04.2 LTS
- Zookeeper is not puppetized in this module, as Debian/Ubuntu provides
  a different and suitable Zookeeper package.  To puppetize Zookeeper Servers,
  See the [puppet-zookeeper](https://github.com/wikimedia/puppet-zookeeper) module.


# Installation

Clone (or copy) this repository into your puppet modules/cdh directory:
```bash
git clone git://github.com/wikimedia/puppet-cdh.git modules/cdh
```

Or you could also use a git submodule:
```bash
git submodule add git://github.com/wikimedia/puppet-cdh.git modules/cdh
git commit -m 'Adding modules/cdh as a git submodule.'
git submodule init && git submodule update
```

# Hadoop

## Hadoop Clients

All Hadoop enabled nodes should include the ```cdh::hadoop``` class.

```puppet
class my::hadoop {
    class { 'cdh::hadoop':
        # Logical Hadoop cluster name.
        cluster_name       => 'mycluster',
        # Must pass an array of hosts here, even if you are
        # not using HA and only have a single NameNode.
        namenode_hosts     => ['namenode1.domain.org'],
        datanode_mounts    => [
            '/var/lib/hadoop/data/a',
            '/var/lib/hadoop/data/b',
            '/var/lib/hadoop/data/c'
        ],
        # You can also provide an array of dfs_name_dirs.
        dfs_name_dir       => '/var/lib/hadoop/name',
    }
}

node 'hadoop-client.domain.org' {
    include my::hadoop
}
```

This will ensure that CDH5 client packages are installed, and that
Hadoop related config files are in place with proper settings.

The datanode_mounts parameter assumes that you want to keep your
DataNode and YARN specific data in subdirectories in each of the mount
points provided.

## Hadoop Master

```puppet
class my::hadoop::master {
    include cdh::hadoop::master
}

node 'namenode1.domain.org' {
    include my::hadoop::master
}
```

This installs and starts up the NameNode.  If using YARN this will install
and set up ResourceManager and HistoryServer.  If using MRv1, this will install
and set up the JobTracker.

## Hadoop Workers

```puppet
class my::hadoop::worker {
    include cdh::hadoop::worker
}

node 'datanode[1234].domain.org' {
    include my::hadoop::worker
}
```

This installs and starts up the DataNode.  If using YARN, this will install
and set up the NodeManager.  If using MRv1, this will install and set up the
TaskTracker.

## High Availability

### High Availibility NameNode

For detailed documentation, see the
[CDH5 High Availability Guide](http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-High-Availability-Guide/cdh5hag_hdfs_ha_config.html).

This puppet module supports Quorum-based HA storage using JournalNodes and HDFS Namenode
Automatic failover via Zookeeper.

Namenode Automatic failover is enabled and configured automatically simply setting
```zookeeper_hosts``` and configuring the JournalNodes.

Your JournalNodes will not be automatically configured based on the value of
```$cdh::hadoop::journalnode_hosts```, but ```cdh::hadoop::journalnode``` should
be specifically instanciated where needed.

Before applying ```cdh::hadoop::journalnode```, make sure the
```dfs_journalnode_edits_dir``` is partitioned and mounted on each of the hosts
in ```journalnode_hosts```.

When setting up a new cluster, you should ensure that your JournalNodes are up
and running before your NameNodes.  When the NameNode is formatted for the first
time, it will talk to the JournalNodes and tell them to initialize their shared
edits directories.  If you are adding HA to an existing cluster, you will need
to initialize your JournalNodes manually.  See section below on how to do this.

You'll need to set two extra parameters on the ```cdh::hadoop``` class on all
your hadoop nodes, as well as specify the hosts of your standby NameNodes.

```puppet

class my::hadoop {
    class { 'cdh::hadoop':
        cluster_name        => 'mycluster',
        namenode_hosts      => [
            'namenode1.domain.org',
            'namenode2.domain.org
        ],
        journalnode_hosts   => [
            'datanode1.domain.org',
            'datanode2.domain.org',
            'datanode3.domain.org'
        ],
        datanode_mounts    => [
            '/var/lib/hadoop/data/a',
            '/var/lib/hadoop/data/b',
            '/var/lib/hadoop/data/c'
        ],
        dfs_name_dir       => ['/var/lib/hadoop/name', '/mnt/hadoop_name'],
    }
}

node 'hadoop-client.domain.org' {
    include my::hadoop
}
```

Note the differences from the non-HA setup:

- Multiple ```namenode_hosts``` have been given.  You will need to include
```cdh::hadoop::namenode::standby``` on your standby NameNodes.
- ```journalnode_hosts``` have been specified.

On your standby NameNodes, instead of including ```cdh::hadoop::master```,
include ```cdh::hadoop::namenode::standby```:

``` puppet
class my::hadoop::master {
    include cdh::hadoop::master
}
class my::hadoop::standby {
    include cdh::hadoop::namenode::standby
}

node 'namenode1.domain.org' {
    include my::hadoop::master
}

node 'namenode2.domain.org' {
    include my::hadoop::standby
}
```

Including ```cdh::hadoop::namenode::standby``` will bootstrap the standby
NameNode from the primary NameNode and start the standby NameNode service.

When are setting up brand new Hadoop cluster with HA, you should apply your
puppet manifests to nodes in this order:

1. JournalNodes
2. Primary Hadoop master node (active NameNode)
3. StandBy NameNodes
4. Worker nodes (DataNodes)

#### Adding High Availability NameNode to a running cluster

Go through all of the same steps as described in the above section.  Once all
of your puppet manifests have been applied (JournalNodes running, NameNodes running and
formatted/bootstrapped, etc.) you can initialize your
JournalNodes' shared edit directories.

```bash

# Shutdown your HDFS cluster.  Everything will need a
# restart on order to load the newly applied HA configs.
# (Leave the JournalNodes running.)

# On your hadoop master node:
sudo service hadoop-yarn-resourcemanager stop
sudo service hadoop-hdfs-namenode stop

# If HDFS Automatic Failover is configured for the Master node:
sudo service hadoop-hdfs-zkfc stop

# On your hadoop worker nodes:
sudo service hadoop-hdfs-datanode stop
sudo service hadoop-yarn-nodemanager stop


# Now run the following commands on your primary active NameNode.

# initialize the JournalNodes' shared edit directories:
sudo -u hdfs /usr/bin/hdfs namenode -initializeSharedEdits

# Now restart your Hadoop master services

# On your hadoop master node:
sudo service hadoop-hdfs-namenode start
sudo service hadoop-yarn-resourcemanager start

# If HDFS Automatic Failover is configured for the Master node:
sudo service hadoop-hdfs-zkfc start

# Now that your primary NameNode is back up, and
# JournalNodes have been initialized, bootstrap
# your Standby NameNode(s).  Run this command
# on your standby NameNode(s):
sudo -u hdfs /usr/bin/hdfs namenode -bootstrapStandby

# On your hadoop worker nodes:
sudo service hadoop-yarn-nodemanager start
sudo service hadoop-hdfs-datanode start
```

When there are multiple NameNodes and automatic failover is not configured (it is enabled by setting
```zookeeper_hosts```), both NameNodes start up in standby mode. You will have to manually transition one of them to active.

```bash
# on your hadoop master node:
sudo -u hdfs /usr/bin/hdfs haadmin -transitionToActive <namenode_id>
```

```<namenode_id>``` will be the first entry in the ```$namenode_hosts``` array,
with dot ('.') characters replaced with dashes ('-').  E.g.  ```namenode1-domain-org```.


### High Availability YARN ResourceManager
To configure automatic failover for the ResourceManager, you'll need a running
zookeeper cluster.  If both $resourcemanager_hosts (which defaults to the value you
provide for $namenode_hosts) has multiple hosts set and $zookeeper_hosts is set, then yarn-site.xml
will be configured to use HA ResourceManager.

This module does not support running HA ResourceManager without also running
HA NameNodes.  Your primary NameNode and primary ResourceManager must be configured
to run on the same host via the inclusion of the ```cdh::hadoop::master``` class.
Make sure that the first host listed in $namenode_hosts and in $resoucemanager_hosts
is this primary node (namenode1.domain.org in the following example).

```puppet
class my::hadoop {
    class { 'cdh::hadoop':
        cluster_name        => 'mycluster',
        zookeeper_hosts     => [
            'zk1.domain.org:2181',
            'zk2.domain.org:2181',
            'zk3.domain.org:2181'
        ],
        namenode_hosts      => [
            'namenode1.domain.org',
            'namenode2.domain.org
        ],
        journalnode_hosts   => [
            'datanode1.domain.org',
            'datanode2.domain.org',
            'datanode3.domain.org'
        ],
        datanode_mounts    => [
            '/var/lib/hadoop/data/a',
            '/var/lib/hadoop/data/b',
            '/var/lib/hadoop/data/c'
        ],
        dfs_name_dir       => ['/var/lib/hadoop/name', '/mnt/hadoop_name'],
    }
}

```

Note the differences from the non-HA RM setup:

- zookeeper_hosts has been provided.  This list of hosts will be used for auto failover of the RM.
- On your standby ResourceManagers, explicitly include ```cdh::hadoop::resourcemanager```.

``` puppet
class my::hadoop::master {
    include cdh::hadoop::master
}
class my::hadoop::standby {
    include cdh::hadoop::namenode::standby
    include cdh::hadoop::resourcemanager
}

node 'namenode1.domain.org' {
    include my::hadoop::master
}

node 'namenode2.domain.org' {
    include my::hadoop::standby
}
```

#### Adding High Availability YARN ResourceManager to a running cluster
Apply the above puppetization to your nodes, and then restart all YARN services (ResouceManagers and NodeManagers).


# Hive

## Hive Clients

```puppet
class { 'cdh::hive':
  metastore_host  => 'hive-metastore-node.domain.org',
  zookeeper_hosts => ['zk1.domain.org', 'zk2.domain.org', 'zk3.domain.org'],
  jdbc_password   => $secret_password,
}
```

## hive-server2 and hive-metastore

Include the same ```cdh::hive``` class as indicated above, and then:

```puppet
class { 'cdh::hive::server': }
class { 'cdh::hive::metastore': }

```

By default, a Hive metastore backend MySQL database will be used.  You must
separately ensure that your metastore database (e.g. mysql) package is
installed.


# Oozie

## Oozie Clients

```puppet
class { 'cdh::oozie': }
```

## Oozie Server

The following will install and run oozie-server, as well as create a MySQL
database for it to use. A MySQL database is the only currently supported
automatically installable backend database.  Alternatively, you may set
```database => undef``` to avoid setting up MySQL and then configure your own
Oozie database manually.  The database much be reachable using the
```$jdbc_*``` parameters.  If ```$jdbc_protocol = 'mysql'```, a mysql client
must be available at /usr/bin/mysql.

```puppet
class { 'cdh::oozie::server:
  jdbc_password -> $secret_password,
}
```


# Hue

To install hue server, simply:

```puppet
class { 'cdh::hue':
    secret_key       => 'ii7nnoCGtP0wjub6nqnRfQx93YUV3iWG', # your secret key here.
    hive_server_host => 'hive.example.com',
}
```

## The Hue database

By default Hue uses a Sqlite database with the following settings:

```
    database_engine    => 'sqlite3'
    database_name      => '/var/lib/hue/desktop.db'
```

It is possible to use a external database but schema, tables and username
need to be pre-configured by other means:

```
    database_host      => 'localhost'
    database_port      => '3316'
    database_user      => 'hue'
    database_password  => 'hue'
    database_name      => 'hue'
    database_engine    => 'mysql'
```

There are many more parameters to the ```cdh::hue``` class.  See the class
documentation in manifests/hue.pp.

If you include ```cdh::hive``` or ```cdh::oozie``` classes on this node,
Hue will be configured to run its Hive and Oozie apps.
