#SPDX-License-Identifier: Apache-2.0
# @summary
#   Install and configure reprepro on a server
#
# @param homedir
#   The reprepro user home directory.
# @param basedir
#   The reprepro base directory, for the public packages.
# @param user
#   The user used for reprepro
# @param group
#   The group used for reprepro
# @param gpg_secring
#   The GPG secret keyring for reprepro to use. Will be passed to secret()
# @param gpg_pubring
#   The GPG public keyring for reprepro to use. Will be passed to secret()
# @param gpg_user
#   The user owning the GPG keys for package signing, typically root.
# @param authorized_keys
#   List of authorized keys, used for uploading
class aptrepo::common (
    Stdlib::Unixpath $homedir         = '/var/lib/reprepro',
    Stdlib::Unixpath $basedir         = '/var/lib/reprepro',
    String           $user            = 'reprepro',
    String           $group           = 'reprepro',
    Optional[String] $gpg_secring     = undef,
    Optional[String] $gpg_pubring     = undef,
    Optional[String] $gpg_user        = undef,
    Array[String]    $authorized_keys = [],
) {
    $packages = ['reprepro','dpkg-dev','dctrl-tools','gnupg','zip']
    ensure_packages($packages)

    # Basic reprepro configuration. By setting the PREPREPRO_BASE_DIR,
    # we're making reprepro a little easier to use in the most common
    # cases, by defaulting to the publically available repository.
    file { "${homedir}/.bashrc":
        ensure => file,
        owner  => $user,
        group  => $group,
    }

    file_line { 'reprepro_bashrc':
      ensure => present,
      path   => "${homedir}/.bashrc",
      line   => "export REPREPRO_BASE_DIR=${basedir}  # Managed by puppet",
    }

    # Configure GnuPG for package signing.
    file { "${homedir}/.gnupg":
        ensure => directory,
        owner  => $gpg_user,
        group  => $gpg_user,
        mode   => '0700',
    }

    if $gpg_secring != undef {
        file { "${homedir}/.gnupg/secring.gpg":
            ensure    => file,
            owner     => $gpg_user,
            group     => $gpg_user,
            mode      => '0400',
            content   => wmflib::secret($gpg_secring, true),
            show_diff => false,
        }
    }

    if $gpg_pubring != undef {
        file { "${homedir}/.gnupg/pubring.gpg":
            ensure  => file,
            owner   => $gpg_user,
            group   => $gpg_user,
            mode    => '0400',
            content => secret($gpg_pubring),
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

    # SSH upload script, currently only for public packages.
    unless $authorized_keys.empty {
        ssh::userkey { 'reprepro':
            content => template('aptrepo/authorized_keys.erb'),
        }
    }

    file { '/usr/local/bin/reprepro-ssh-upload':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/aptrepo/reprepro-ssh-upload',
    }
}
