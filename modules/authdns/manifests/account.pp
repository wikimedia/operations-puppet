# == Class authdns::account
# Sets up user, group, sudo SSH keys & git-shell commands for authdns
#
class authdns::account {
    require_package('git') # for git-shell stuff

    $user  = 'authdns'
    $group = 'authdns'
    $home  = '/srv/authdns'

    user { $user:
        ensure     => present,
        gid        => $group,
        home       => $home,
        system     => true,
        managehome => true,
        shell      => '/usr/bin/git-shell',
        require    => Package['git'],
    }
    group { $group:
        ensure     => 'present',
    }

    sudo::user { $user:
        privileges => ['ALL=NOPASSWD: /usr/local/sbin/authdns-local-update'],
    }

    file { "${home}/.ssh":
        ensure  => 'directory',
        owner   => $user,
        group   => $group,
        mode    => '0700',
        require => [ User[$user], Group[$group] ],
    }
    file { "${home}/.ssh/id_ed25519":
        ensure  => 'present',
        owner   => $user,
        group   => $group,
        mode    => '0400',
        content => secret('authdns/id_ed25519'),
    }
    file { "${home}/.ssh/id_ed25519.pub":
        ensure  => 'present',
        owner   => $user,
        group   => $group,
        mode    => '0400',
        content => secret('authdns/id_ed25519.pub'),
    }
    ssh::userkey { $user:
        content => secret('authdns/id_ed25519.pub'),
    }

    file { "${home}/git-shell-commands":
        ensure  => 'directory',
        owner   => $user,
        group   => $group,
        require => [ User[$user], Group[$group] ],
    }
    file { "${home}/git-shell-commands/authdns-local-update":
        ensure  => 'present',
        owner   => $user,
        group   => $group,
        mode    => '0550',
        content => "#!/bin/sh\nexec /usr/bin/sudo authdns-local-update \$@\n",
        require => [ User[$user], Group[$group] ],
    }
}
