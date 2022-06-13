# SPDX-License-Identifier: Apache-2.0
# == Class bigtop::hadoop::namenode::primary
# Hadoop Primary NameNode.
#
# This class is applied by bigtop::hadoop::master even
# if we aren't using HA Standby Namenodes.  The primary NameNode will be inferred
# as the first entry $bigtop::hadoop::namenode_hosts variable.  If we are using
# HA, then the primary NameNode will be transitioned to active as once NameNode
# has been formatted, before common HDFS directories are created.
#
class bigtop::hadoop::namenode::primary(
    $excluded_hosts = [],
) {

    class { 'bigtop::hadoop::namenode':
        excluded_hosts => $excluded_hosts,
    }

    # Go ahead and transision this primary namenode to active if we are using HA.
    if ($::bigtop::hadoop::ha_enabled) {
        $primary_namenode_id = $::bigtop::hadoop::primary_namenode_id

        kerberos::exec { 'haaadmin-transitionToActive':
            # $namenode_id is set in parent bigtop::hadoop::namenode class.
            command     => "/usr/bin/hdfs haadmin -transitionToActive ${primary_namenode_id}",
            unless      => "/usr/bin/hdfs haadmin -getServiceState    ${primary_namenode_id} | /bin/grep -q active",
            user        => 'hdfs',
            # Only run this command if the namenode was just formatted
            # and after the namenode has started up.
            refreshonly => true,
            subscribe   => Exec['hadoop-namenode-format'],
            require     => Service['hadoop-hdfs-namenode'],
        }
        # Make sure NameNode is running and active
        # before we try to create common HDFS directories.
        Bigtop::Hadoop::Directory {
            require => Exec['haaadmin-transitionToActive'],
        }
    }
    else {
        # Make sure NameNode is running
        # before we try to create common HDFS directories.
        Bigtop::Hadoop::Directory {
            require =>  Service['hadoop-hdfs-namenode'],
        }
    }

    # Create common HDFS directories.

    # sudo -u hdfs hdfs dfs -mkdir /tmp
    # sudo -u hdfs hdfs dfs -chmod 1777 /tmp
    bigtop::hadoop::directory { '/tmp':
        owner => 'hdfs',
        group => 'hdfs',
        mode  => '1777',
    }

    # sudo -u hdfs hdfs dfs -mkdir /user
    # sudo -u hdfs hdfs dfs -chmod 0775 /user
    # sudo -u hdfs hdfs dfs -chown hdfs:hadoop /user
    bigtop::hadoop::directory { '/user':
        owner => 'hdfs',
        group => 'hadoop',
        mode  => '0775',
    }

    # sudo -u hdfs hdfs dfs -mkdir /user/hdfs
    bigtop::hadoop::directory { '/user/hdfs':
        owner   => 'hdfs',
        group   => 'hdfs',
        mode    => '0755',
        require => Bigtop::Hadoop::Directory['/user'],
    }

    # sudo -u hdfs hdfs dfs -mkdir /var
    bigtop::hadoop::directory { '/var':
        owner => 'hdfs',
        group => 'hdfs',
        mode  => '0755',
    }

    # sudo -u hdfs hdfs dfs -mkdir /var/lib
    bigtop::hadoop::directory { '/var/lib':
        owner   => 'hdfs',
        group   => 'hdfs',
        mode    => '0755',
        require => Bigtop::Hadoop::Directory['/var'],
    }

    # sudo -u hdfs hdfs dfs -mkdir /var/log
    bigtop::hadoop::directory { '/var/log':
        owner   => 'hdfs',
        group   => 'hdfs',
        mode    => '0755',
        require => Bigtop::Hadoop::Directory['/var'],
    }
}
