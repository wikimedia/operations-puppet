# == Class: keyholder
#
# The keyholder class provides a means of allowing a group of trusted
# users to use a shared SSH identity without exposing the identity's
# private key. This is accomplished by running a pair of SSH agents
# as system services: `keyholder-agent` and `keyholder-proxy`:
# `keyholder-agent` is the actual ssh-agent instance that holds the
# private key. `keyholder-proxy` proxies requests to the agent via a
# domain socket that is owned by the trusted user group. The proxy
# implements a subset of the ssh-agent protocol, allowing users to list
# identities and to use them to sign requests, but not to add or remove
# identities.
#
# The two services bind domain sockets at these addresses:
#
#   /run/keyholder
#   ├── agent.sock (0600)
#   └── proxy.sock (0660)
#
# Before the shared SSH agent can be used, it must be armed by a user
# with access to the private key. This can be done by running:
#
#  $ SSH_AUTH_SOCK=/run/keyholder/agent.sock ssh-add /path/to/key
#
# Users in the trusted group can use the shared agent by running:
#
#  $ SSH_AUTH_SOCK=/run/keyholder/proxy.sock ssh remote-host ...
#
# === Parameters
#
# [*trusted_group*]
#   The name or GID of the trusted user group with which the agent
#   should be shared. It is the caller's responsibility to ensure
#   the group exists.
#
# === Examples
#
#  class { 'keyholder':
#      trusted_group => 'wikidev',
#      require       => Group['wikidev'],
#  }
#
# === Bugs
#
# It is currently only possible to have a single agent / proxy pair
# (shared with just one group) on a particular node.
#
class keyholder( $trusted_group ) {
    group { 'keyholder':
        ensure => present,
    }

    user { 'keyholder':
        ensure     => present,
        gid        => 'keyholder',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
        managehome => false,
    }

    file { '/etc/default/keyholder':
        content => "KEYHOLDER_GROUP=${trusted_group}\n",
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['keyholder-agent'],
    }

    file { '/usr/local/bin/ssh-agent-proxy':
        source => 'puppet:///modules/keyholder/ssh-agent-proxy',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        notify => Service['keyholder-agent'],
    }


    # Log all system calls that access the keyholder's agent
    # and proxy sockets from users in the trusted user group.

    auditd::rules { 'keyholder':
        content => template('keyholder/keyholder.rules.erb'),
        before  => Service['keyholder-agent'],
    }


    # The `keyholder-agent` service is responsible for running
    # the ssh-agent instance that will hold shared key(s).

    file { '/etc/init/keyholder-agent.conf':
        source => 'puppet:///modules/keyholder/keyholder-agent.conf',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Service['keyholder-agent'],
    }

    service { 'keyholder-agent':
        ensure   => running,
        provider => 'upstart',
        require  => User['keyholder'],
    }


    # The `keyholder-proxy` service runs the filtering ssh-agent proxy
    # that acts as an intermediary between users in the trusted group
    # and the backend ssh-agent that holds the shared key(s).

    file { '/etc/init/keyholder-proxy.conf':
        source => 'puppet:///modules/keyholder/keyholder-proxy.conf',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Service['keyholder-proxy'],
    }

    service { 'keyholder-proxy':
        ensure   => running,
        provider => 'upstart',
        require  => Service['keyholder-agent'],
    }
}
