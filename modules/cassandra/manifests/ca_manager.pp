# == Class: cassandra::ca_manager
#
# Install a symlink as cassandra-ca-manager to ca-manager.
# This maintains backwards compatibility for anyone who doesn't
# yet know that cassandra-ca-manager has been made generic.
# See: https://phabricator.wikimedia.org/T166167
#
# The manager will accept a manifest file as input and generate a CA plus all
# related certificates to be installed on cassandra nodes.
# Note: per-cluster manifests and secrets live in private.git.
#
# === Usage
# class { '::cassandra::ca_manager': }

class cassandra::ca_manager {
    require ::ca::manager

    file { '/usr/local/bin/cassandra-ca-manager':
        ensure => 'link',
        target => '/usr/local/bin/ca-manager',
    }
}
