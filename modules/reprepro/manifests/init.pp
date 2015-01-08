# == Class: reprepro
#
#   Configures reprepro on a server
#
# === Parameters
#
#   - *basedir*: The reprepro base directory.
#   - *homedir*: The reprepro user home directory.
#   - *user*: The user name to run reprepro under.
#   - *group*: The group name to run reprepro under.
#   - *notify_address*: Where to send upload notifications.
#   - *options*: A list of options for reprepro (see conf/options file).
#   - *uploaders*: A list of uploaders instructions (see "uploaders file")
#   - *incomingdir*: Path considered for incoming uploads.
#   - *default_distro*: The default distribution if none specified.
#   - *gpg_secring*: The GPG secret keyring for reprepro to use.
#   - *gpg_pubring*: The GPG public keyring for reprepro to use.
#   - *authorized_keys*: A list of ssh public keys allowed to upload and process the incoming queue
#
# === Example
#
#   class { 'reprepro':
#       basedir => "/tmp/reprepro",
#   }
#
class reprepro (
    $basedir,
    $homedir         = '/var/lib/reprepro',
    $user            = 'reprepro',
    $group           = 'reprepro',
    $notify_address  = 'root@wikimedia.org',
    $options         = [],
    $uploaders       = [],
    $incomingdir     = 'incoming',
    $default_distro  = 'trusty',
    $gpg_secring     = undef,
    $gpg_pubring     = undef,
    $authorized_keys = [],
) {

    package { 'reprepro':
        ensure => present,
    }

    group { 'reprepro':
        ensure => present,
        name   => $group,
    }

    user { 'reprepro':
        ensure     => present,
        name       => $user,
        home       => $homedir,
        shell      => '/bin/sh',
        comment    => 'Reprepro user',
        gid        => $group,
        managehome => true,
        require    => Group['reprepro'],
    }

    file { $basedir:
        ensure  => directory,
        owner   => $user,
        group   => $group,
        mode    => '0755',
        require => User['reprepro'],
    }

    file { "${basedir}/conf":
        ensure  => directory,
        owner   => $user,
        group   => $group,
        mode    => '0555',
        require => User['reprepro'],
    }

    file { "${basedir}/db":
        ensure  => directory,
        owner   => $user,
        group   => $group,
        mode    => '0755',
        require => User['reprepro'],
    }

    file { "${basedir}/logs":
        ensure  => directory,
        owner   => $user,
        group   => $group,
        mode    => '0755',
        require => User['reprepro'],
    }

    file { "${basedir}/tmp":
        ensure  => directory,
        owner   => $user,
        group   => $group,
        mode    => '0755',
        require => User['reprepro'],
    }

    file { "${basedir}/conf/options":
        ensure  => file,
        owner   => $user,
        group   => $group,
        mode    => '0444',
        content => inline_template("<%= @options.join(\"\n\") %>\n"),
    }

    file { "${basedir}/conf/uploaders":
        ensure  => file,
        owner   => $user,
        group   => $group,
        mode    => '0444',
        content => inline_template("<%= @uploaders.join(\"\n\") %>\n"),
    }

    file { "${basedir}/conf/incoming":
        ensure  => file,
        owner   => $user,
        group   => $group,
        mode    => '0444',
        content => template("reprepro/incoming.erb"),
    }

    file { "${basedir}/conf/log":
        ensure  => file,
        owner   => $user,
        group   => $group,
        mode    => '0755',
        content => template("reprepro/log.erb"),
    }

    file { "${homedir}/.gnupg":
        ensure  => directory,
        owner   => $user,
        group   => $group,
        mode    => '0700',
        require => User['reprepro'],
    }

    ssh::userkey { 'reprepro':
        content => template("reprepro/authorized_keys.erb"),
    }

    file { "/usr/local/bin/reprepro-ssh-upload":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => User['reprepro'],
        source  => 'puppet:///modules/reprepro/reprepro-ssh-upload',
    }

    if $gpg_secring != undef {
        file { "${homedir}/.gnupg/secring.gpg":
            ensure  => file,
            owner   => $user,
            group   => $group,
            mode    => '0400',
            source  => $gpg_secring,
            require => User['reprepro'],
        }
    }

    if $gpg_pubring != undef {
        file { "${homedir}/.gnupg/pubring.gpg":
            ensure  => file,
            owner   => $user,
            group   => $group,
            mode    => '0400',
            source  => $gpg_pubring,
            require => User['reprepro'],
        }
    }
}
