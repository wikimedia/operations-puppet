# == Class role::analytics_cluster::druid
# For the time being, all Druid services are hosted on all druid nodes
# in the Analytics Cluster.  This may change if and when we expand
# the Druid cluster beyond 3 nodes.
#
# Druid module parameters are configured via hiera.
#
# Druid Zookeeper settings will default to using the hosts in
# the hiera zookeeper_hosts hiera variable.  Druid Zookeeper chroot will
# be set according to $site in production, or $realm in labs.
#
class role::analytics_cluster::druid
{
    # Need Java before Druid is installed.
    require role::analytics_cluster::java

    $zookeeper_chroot = $::realm ? {
        'labs'       => "/druid/analytics-${::labsproject}",
        'production' => "/druid/analytics-${::site}",
    }

    $zookeeper_properties = {
        'druid.zk.service.host' =>
            join(keys(hiera(
                'zookeeper_hosts',
                # Default to running a single zk locally.
                {'localhost:2181' => {'id' => '1'}}
            )), ','),
        'druid.zk.paths.base'   => $zookeeper_chroot,
    }

    # Look up druid::properties out of hiera.  Since class path
    # lookup does not do hiera hash merging, we do so manually here.
    $hiera_druid_properties = hiera_hash('druid::properties', {})

    # If HDFS is being used as deep storage, then require a hadoop client
    # and ensure that HDFS druid directories exist.
    if $hiera_druid_properties['druid.storage.type'] == 'hdfs' {
        # Ensure the Analytics Cluster Hadoop Client is installed.
        require role::analytics_cluster::hadoop::client

        # TODO: This might need to be in its own class and
        # included separately on the HDFS namenode.  We also
        # might need to ensure that the druid user exists on the namenode.

        # Ensure that HDFS directories for druid deep storage are created.
        cdh::hadoop::directory { '/user/druid':
            owner  => 'druid',
            group  => 'hadoop',
            mode   => '0775',
            before => Class['::druid'],
        }
        cdh::hadoop::directory { '/user/druid/deep-storage':
            owner   => 'druid',
            group   => 'hadoop',
            mode    => '0775',
            require => Cdh::Hadoop::Directory['/user/druid'],
        }

        # Symlink the hadoop configs into /etc/druid so they are loaded
        # by Druid daemons.
        file { '/etc/druid/core-site.xml':
            ensure => 'link',
            target => '/etc/hadoop/conf/core-site.xml',
            require => Class['::druid'],
        }
        file { '/etc/druid/hdfs-site.xml':
            ensure => 'link',
            target => '/etc/hadoop/conf/hdfs-site.xml',
            require => Class['::druid'],
        }
        file { '/etc/druid/mapred-site.xml':
            ensure => 'link',
            target => '/etc/hadoop/conf/mapred-site.xml',
            require => Class['::druid'],
        }
        file { '/etc/druid/yarn-site.xml':
            ensure => 'link',
            target => '/etc/hadoop/conf/yarn-site.xml',
            require => Class['::druid'],
        }
    }

    # Druid Common Class
    class { '::druid':
        # Merge our auto configured zookeeper properties
        # with the properties from hiera.
        properties => merge(
            $zookeeper_properties,
            $hiera_druid_properties
        ),
    }


    # Auto reload daemons in labs, but not in production.
    $should_subscribe = $::realm ? {
        'labs'  => true,
        default => false,
    }

    # Druid Broker Service
    class { '::druid::broker':
        should_subscribe => $should_subscribe,
    }

    # Druid Coordinator Service
    class { '::druid::coordinator':
        should_subscribe => $should_subscribe,
    }

    # Druid Historical Service
    class { '::druid::historical':
        should_subscribe => $should_subscribe,
    }

    # Druid MiddleManager Indexing Service
    class { '::druid::middlemanager':
        should_subscribe => $should_subscribe,
    }

    # Druid Overlord Indexing Service
    class { '::druid::overlord':
        should_subscribe => $should_subscribe,
    }
}
