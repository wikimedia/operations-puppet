# == Class: cassandra::ca_manager
#
# Install Cassandra CA manager.
#
# The manager will accept a manifest file as input and generate a CA plus all
# related certificates to be installed on cassandra nodes.
# Note: per-cluster manifests and secrets live in private.git.
#
# === Usage
# class { '::cassandra::ca_manager': }

class cassandra::ca_manager {
    file { '/usr/local/bin/cassandra-ca-manager':
        source => 'puppet:///modules/cassandra-ca-manager.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    # keytool dependency
    package { 'default-jre':
        ensure => present,
    }
}
