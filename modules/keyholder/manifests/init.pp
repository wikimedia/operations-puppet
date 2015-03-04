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
#   |__ agent.sock (0600)
#   |__ proxy.sock (0660)
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

    require_package('python3')

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

    file { '/run/keyholder':
        ensure => directory,
        owner  => 'keyholder',
        group  => 'keyholder',
        mode   => '0755',
    }

    file { '/etc/keyholder.d':
        ensure  => directory,
        owner   => 'keyholder',
        group   => 'keyholder',
        mode    => '0750',
        recurse => true,
        purge   => true,
        force   => true,
    }

    file { '/usr/local/bin/ssh-agent-proxy':
        source => 'puppet:///modules/keyholder/ssh-agent-proxy',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        notify => Service['keyholder-agent'],
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
        require  => File['/run/keyholder'],
    }


    # The `keyholder-proxy` service runs the filtering ssh-agent proxy
    # that acts as an intermediary between users in the trusted group
    # and the backend ssh-agent that holds the shared key(s).

    file { '/etc/init/keyholder-proxy.conf':
        content => template('keyholder/keyholder-proxy.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['keyholder-proxy'],
    }

    service { 'keyholder-proxy':
        ensure   => running,
        provider => 'upstart',
        require  => Service['keyholder-agent'],
    }


    # The `keyholder` script provides a simplified command-line
    # interface for managing the agent. See `keyholder --help`.

    file { '/usr/local/sbin/keyholder':
        source => 'puppet:///modules/keyholder/keyholder',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        notify => Service['keyholder-proxy'],
    }
}
