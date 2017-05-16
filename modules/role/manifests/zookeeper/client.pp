# Classes for Zookeeper nodes.
# These role classes will configure Zookeeper properly in either
# the labs or production environments.
#
# To avoid version conflics with Cloudera zookeeper package, this
# class manually specifies which debian package version should be installed.
# There are sane defaults for Ubunty Trusty and Debian Jessie
# (as of 2017-05 the Jessie version needs updated to 3.4.5+dfsg-2+deb8u1).
# If you need to override this, you may set 'zookeeper_version' in hiera.
#
# Usage:
#
# If you only need Zookeeper client configs to talk to Zookeeper servers:
#   include role::zookeeper::client
#
# If you want to set up a Zookeeper server:
#   include role::zookeeper::server
#
# You need to include the hiera variables 'zookeeper_clusters' and
# 'zookeeper_cluster_name'.  zookeeper_clusters should be a hash with
# zookeeper_cluster_name as a key, the value of which is a hash
# that has a 'hosts' sub with key being name of node and value being zookeeper
# id for the client / server roles to work.
#
# E.g.
#
# # In eqiad.yaml, or role/eqiad/zookeeper/server.yaml:
# zookeeper_cluster_name: main-eqiad
#
# # In common.yaml:
# zookeeper_clusters:
#  main-eqiad:
#   hosts:
#     nodeA: 1
#     nodeB: 2
# ...
#
# == Class role::zookeeper::client
#
class role::zookeeper::client {

    $version = hiera('zookeeper_version',
        $::lsbdistcodename ? {
            'jessie'  => '3.4.5+dfsg-2',
            'trusty'  => '3.4.5+dfsg-1',
        }
    )

    $clusters     = hiera('zookeeper_clusters')
    $cluster_name = hiera('zookeeper_cluster_name')

    require_package('openjdk-7-jdk')
    class { '::zookeeper':
        hosts   => $clusters[$cluster_name]['hosts'],
        version => $version,
    }
}

