# == Class: aptrepo
#
#   Configures apt.wikimedia.org and reprepro on a server
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
#   - *incomingconf*: Name of a template with config options for incoming uploads. (conf/incoming)
#   - *incominguser*: The user name that owns the incoming directory.
#   - *incominggroup*: The group name that owns the incoming directory.
#   - *default_distro*: The default distribution if none specified.
#   - *gpg_secring*: The GPG secret keyring for reprepro to use. Will be passed to secret()
#   - *gpg_pubring*: The GPG public keyring for reprepro to use. Will be passed to secret()
#   - *authorized_keys*: A list of ssh public keys allowed to upload and process the incoming queue
#
# === Example
#
#   class { 'aptrepo':
#       basedir => "/tmp/reprepro",
#   }
#
# TODO: add something that sets up /etc/environment for reprepro
#
class aptrepo (
    $basedir,
    $homedir         = '/var/lib/reprepro',
    $user            = 'reprepro',
    $group           = 'reprepro',
    $notify_address  = 'root@wikimedia.org',
    $options         = [],
    $uploaders       = [],
    $incomingdir     = 'incoming',
    $incomingconf    = 'incoming',
    $incominguser    = 'reprepro',
    $incominggroup   = 'reprepro',
    $default_distro  = 'jessie',
    $gpg_secring     = undef,
    $gpg_pubring     = undef,
    $authorized_keys = [],
) {

    # While runnning the repository on jessie, use 5.1.1 from
    # backports which supports dbgsym packages and buildinfo files
    if os_version('debian == jessie') {
        apt::pin {'reprepro':
            pin      => 'release a=jessie-backports',
            priority => '1001',
            before   => Package['reprepro'],
        }
    }

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
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { "${basedir}/conf":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { "${basedir}/conf/updates":
        ensure => present,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/aptrepo/updates',
    }

    file { "${basedir}/conf/pulls":
        ensure => present,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/aptrepo/pulls',
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
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("aptrepo/${incomingconf}.erb"),
    }

    file { "${basedir}/conf/log":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => template('aptrepo/log.erb'),
    }

    file { "${basedir}/db":
        ensure  => directory,
        owner   => $user,
        group   => $group,
        mode    => '0755',
        require => User['reprepro'],
    }

    file { "${basedir}/incoming":
        ensure => directory,
        mode   => '1775',
        owner  => $incominguser,
        group  => $incominggroup,
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

    file { "${homedir}/.gnupg":
        ensure  => directory,
        owner   => $user,
        group   => $group,
        mode    => '0700',
        require => User['reprepro'],
    }

    ssh::userkey { 'reprepro':
        content => template('aptrepo/authorized_keys.erb'),
    }

    file { '/usr/local/bin/reprepro-ssh-upload':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => User['reprepro'],
        source  => 'puppet:///modules/aptrepo/reprepro-ssh-upload',
    }

    if $gpg_secring != undef {
        file { "${homedir}/.gnupg/secring.gpg":
            ensure    => file,
            owner     => $user,
            group     => $group,
            mode      => '0400',
            content   => secret($gpg_secring),
            show_diff => false,
            require   => User['reprepro'],
        }
    }

    if $gpg_pubring != undef {
        file { "${homedir}/.gnupg/pubring.gpg":
            ensure  => file,
            owner   => $user,
            group   => $group,
            mode    => '0400',
            content => secret($gpg_pubring),
            require => User['reprepro'],
        }
    }

    # apt repository managements tools
    package { [
        'dpkg-dev',
        'dctrl-tools',
        'gnupg',
        ]:
        ensure => present,
    }

}

