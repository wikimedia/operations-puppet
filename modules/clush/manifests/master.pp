# = Class: clush::master
#
# Sets up a clush (clustershell) master, that is designed
# to ssh into instances with the class clush::target
# installed. It sets it up to be usable only by root. Expects
# a private key of the form secret('clush/${username}') to be
# available.
#
# It sets up a default clush config that can be overriden
# on the commandline. Most important default is probably
# the fanout value of 16 - so all commands will be executed
# 16 instances at a time.
#
# == Parameters
# [*username*]
#   Username to ssh into targets as. Should match what is
#   used with clush::target
# [*ensure*]
#   Make the master be present or absent. Defaults to present
class clush::master(
    $username,
    $ensure = present,
) {
    # clush has not been vetted for use in production
    # See T143306
    requires_realm('labs')

    file { '/root/.ssh':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0700',
    }

    file { "/root/.ssh/${username}":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File['/root/.ssh'],
        content => secret("clush/${username}"),
    }

    require_package('clustershell')

    $config = {
        'Main' => {
            # Default fanout to 16!
            'fanout'          => 16,
            'connect_timeout' => 15,
            'command_timeout' => 0,
            'color'           => 'auto',
            'fd_max'          => '16384',
            'history_size'    => 1024,
            'node_count'      => 'yes',
            'verbosity'       => 1,
            'ssh_user'        => $username,
            # We disable strict host key checking. If
            # someone can MITM us here we are screwed
            # anyway.
            'ssh_options'     => "-i /root/.ssh/${username} -oStrictHostKeyChecking=no",
        },
    }

    file { '/etc/clustershell/clush.conf':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => ini($config),
    }
}
