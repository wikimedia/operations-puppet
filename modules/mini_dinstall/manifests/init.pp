# == Class: mini_dinstall
#
# This module configures mini-dinstall, a debian repository manager.
#
# === Parameters
#
# [*root_dir*]
#   The root directory where to install repository-related files.
#
# [*keyid*]
#   What gpg key ID to use to sign Release files
#
# [*archive_dir*]
#   Where to store archive files themselves (indices, .deb files, etc)
#
# [*gnupg_home*]
#   Where to find gpg keyring
#
# [*owner*]
#   User owning the archive (including incoming/ directory)
#
# [*group*]
#   Group owning the archive (including incoming/ directory)

class mini_dinstall(
    $root_dir,
    $keyid,
    $archive_dir = "${root_dir}/debian",
    $gnupghome = "${root_dir}/.gnupg",
    $owner = 'root',
    $group = 'wikidev',
) {
    $md_config_path = "${root_dir}/mini-dinstall.conf"
    $sign_release_path = "${root_dir}/sign-release"

    package { ['mini-dinstall', 'gnupg']:
        ensure => 'present',
    }

    file { [$root_dir, $archive_dir]:
        ensure => 'directory',
        owner  => $owner,
        group  => $group,
        mode   => '0755',
    }

    file { $gnupghome:
        ensure => 'directory',
        owner  => $owner,
        group  => $group,
        mode   => '0700',
    }

    file { ["${archive_dir}/mini-dinstall",
            "${archive_dir}/mini-dinstall/incoming"]:
        ensure => 'directory',
        owner  => $owner,
        group  => $group,
        mode   => '0770',
    }

    file { $md_config_path:
        ensure  => 'present',
        content => template('mini_dinstall/mini-dinstall.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { $sign_release_path:
        ensure  => 'present',
        content => template('mini_dinstall/sign-release.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
    }
}
