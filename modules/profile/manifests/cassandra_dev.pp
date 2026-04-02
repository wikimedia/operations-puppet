# SPDX-License-Identifier: Apache-2.0

# Cassandra dev & test environment (T324113)
class profile::cassandra_dev (
    Hash[String, String] $cassandra_passwords = lookup('profile::cassandra::user_credentials', {'default_value' => {}}),
) {
    $devuser          = 'cassandra_devel'
    $devpasswd        = $cassandra_passwords[$devuser]

    class {'passwords::cassandra': }

    # Temporary ----------------------------------------------------------------
    # In order to perform testing of the linked-artifacts caching service prior
    # to having any (k8s) deployed lambdas, we are running the sample rpc server
    # from one or more of the cassandra-dev cluster nodes.  Once we have an
    # actual lambda deployed, this should be removed, and
    # https://phabricator.wikimedia.org/T421444 closed.

    # Deploy docker to run the example echo server shipped with hoarde.
    ensure_packages(['docker.io', 'apparmor'])

    # Allow the k8s staging cluster to connect.
    ferm::service { 'echo-lambda':
        proto  => 'tcp',
        port   => 50051,
        srange => '$STAGING_KUBEPODS_NETWORKS',
    }
    # Temporary ----------------------------------------------------------------

    # Surrogate user for dev team cqlsh access
    group { $devuser:
        ensure => present,
        system => true,
    }

    user { $devuser:
        ensure     => present,
        gid        => $devuser,
        home       => "/var/lib/${devuser}",
        shell      => '/bin/false',
        system     => true,
        managehome => true,
    }

    file { "/var/lib/${devuser}/.cassandra":
        ensure  => 'directory',
        owner   => $devuser,
        group   => $devuser,
        mode    => '0700',
        require => User[$devuser],
    }

    file { "/var/lib/${devuser}/.cassandra/cqlshrc":
        owner   => $devuser,
        group   => $devuser,
        mode    => '0440',
        content => template('profile/cassandra_dev/cqlshrc.erb'),
        require => File["/var/lib/${devuser}/.cassandra"],
    }

    file { "/var/lib/${devuser}/.cassandra/credentials":
        owner   => $devuser,
        group   => $devuser,
        mode    => '0400',
        content => template('profile/cassandra_dev/credentials.erb'),
        require => File["/var/lib/${devuser}/.cassandra"],
    }
}
