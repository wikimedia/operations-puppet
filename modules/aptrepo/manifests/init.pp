# SPDX-License-Identifier: Apache-2.0
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
    Stdlib::Unixpath $basedir         = '/var/lib/reprepro',
    Stdlib::Unixpath $homedir         = '/var/lib/reprepro',
    String           $user            = 'reprepro',
    String           $group           = 'reprepro',
    String           $notify_address  = 'root@wikimedia.org',
    Array[String]    $options         = [],
    Array[String]    $uploaders       = [],
    String           $incomingdir     = 'incoming',
    String           $incomingconf    = 'incoming',
    String           $incominguser    = 'reprepro',
    String           $incominggroup   = 'reprepro',
    String           $default_distro  = 'buster',
    Optional[String] $gpg_secring     = undef,
    Optional[String] $gpg_pubring     = undef,
    Optional[String] $gpg_user        = undef,
    Array[String]    $authorized_keys = [],
) {

    $common_packages = ['reprepro','dpkg-dev','dctrl-tools','gnupg',]

    if(debian::codename::ge('bullseye')) {
        $packages = $common_packages << 'python3-apt'
    } else {
        $packages = $common_packages << 'python-apt'
    }

    ensure_packages($packages)

    if(debian::codename::ge('bullseye')) {
        $deb822_validate_cmd = '/usr/bin/python3 -c "import apt_pkg; f=\'%\'; list(apt_pkg.TagFile(f))"'
    } else {
        $deb822_validate_cmd = '/usr/bin/python -c "import apt_pkg; f=\'%\'; list(apt_pkg.TagFile(f))"'
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
        ensure       => present,
        mode         => '0444',
        owner        => 'root',
        group        => 'root',
        source       => 'puppet:///modules/aptrepo/updates',
        validate_cmd => $deb822_validate_cmd,
    }

    file { "${basedir}/conf/pulls":
        ensure       => present,
        mode         => '0444',
        owner        => 'root',
        group        => 'root',
        source       => 'puppet:///modules/aptrepo/pulls',
        validate_cmd => $deb822_validate_cmd,
    }

    file { "${basedir}/conf/options":
        ensure       => file,
        owner        => $user,
        group        => $group,
        mode         => '0444',
        content      => inline_template("<%= @options.join(\"\n\") %>\n"),
        validate_cmd => $deb822_validate_cmd,
    }

    file { "${basedir}/conf/uploaders":
        ensure       => file,
        owner        => $user,
        group        => $group,
        mode         => '0444',
        content      => inline_template("<%= @uploaders.join(\"\n\") %>\n"),
        validate_cmd => $deb822_validate_cmd,
    }

    file { "${basedir}/conf/incoming":
        ensure       => present,
        owner        => 'root',
        group        => 'root',
        mode         => '0444',
        content      => template("aptrepo/${incomingconf}.erb"),
        validate_cmd => $deb822_validate_cmd,
    }

    $log_script = @("SCRIPT"/$)
    #!/bin/bash
    echo -e "reprepro changes:\n\$@" | mail -s "Reprepro changes" ${notify_address}
    | SCRIPT
    file { "${basedir}/conf/log":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => $log_script,
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
        owner   => $gpg_user,
        group   => $gpg_user,
        mode    => '0700',
        require => User['reprepro'],
    }

    unless $authorized_keys.empty {
        ssh::userkey { 'reprepro':
            content => template('aptrepo/authorized_keys.erb'),
        }
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
            owner     => $gpg_user,
            group     => $gpg_user,
            mode      => '0400',
            content   => secret($gpg_secring),
            show_diff => false,
            require   => User['reprepro'],
        }
    }

    if $gpg_pubring != undef {
        file { "${homedir}/.gnupg/pubring.gpg":
            ensure  => file,
            owner   => $gpg_user,
            group   => $gpg_user,
            mode    => '0400',
            content => secret($gpg_pubring),
            require => User['reprepro'],
        }
    }

    file { "${homedir}/.gnupg/reprepro-updates-keys.d":
        ensure  => directory,
        owner   => $gpg_user,
        group   => $gpg_user,
        mode    => '0550',
        recurse => true,
        purge   => true,
        source  => 'puppet:///modules/aptrepo/updates-keys',
        notify  => Exec['reprepro-import-updates-keys'],
    }

    exec { 'reprepro-import-updates-keys':
        refreshonly => true,
        provider    => 'shell',
        command     => "/usr/bin/gpg --import ${homedir}/.gnupg/reprepro-updates-keys.d/*.gpg",
    }

    file_line { 'reprepro_basedir':
      ensure => present,
      path   => "${homedir}/.bashrc",
      line   => "export REPREPRO_BASE_DIR=${basedir}  # Managed by puppet",
    }
}
