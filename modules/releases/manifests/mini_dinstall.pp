# == Class: releases::mini_dinstall
#
# This module adds mini-dinstall capabilities to releases module.
# GPG signing of Release file is supported via an external script, to protect
# access to the key material mini-dinstall should be invoked via sudo by
# members of $group.
#
# === Parameters
#
# [*keyid*]
#   What gpg key ID to use to sign Release files
#
# [*root_dir*]
#   The root directory where to install repository-related files.
#
# [*archive_dir*]
#   Where to store archive files themselves (indices, .deb files, etc)
#
# [*owner*]
#   The owner of archive directory and related files
#
# [*group*]
#   Group owning the archive (including incoming/ directory)

class releases::mini_dinstall (
    $keyid,
    $root_dir = '/srv/org/wikimedia/mini-dinstall',
    $archive_dir = '/srv/org/wikimedia/releases/debian',
    $owner = 'mini-dinstall',
    $group = 'releasers-mediawiki',
) {
    generic::systemuser { $owner:
        name => $owner,
        home => $root_dir,
    }

    sudo_group { 'mini-dinstall_sudo':
        privileges => ["ALL = (${owner}) NOPASSWD: /usr/bin/mini-dinstall"],
        group      => $group,
        require    => Group[$group],
    }

    file { "${root_dir}/.gnupg/secring.gpg":
        ensure => 'present',
        source => 'puppet:///private/gpg/releases/secring.gpg',
        owner  => $owner,
        group  => $group,
        mode   => '0600',
    }

    file { "${root_dir}/.gnupg/pubring.gpg":
        ensure => 'present',
        source => 'puppet:///private/gpg/releases/pubring.gpg',
        owner  => $owner,
        group  => $group,
        mode   => '0600',
    }

    file { "${root_dir}/dput.cf":
        ensure  => 'present',
        content => template('releases/dput.cf.erb'),
        owner   => $owner,
        group   => $group,
        mode    => '0644',
    }

    class { '::mini_dinstall':
        root_dir    => $root_dir,
        archive_dir => $archive_dir,
        owner       => $owner,
        group       => $group,
        keyid       => $keyid,
    }
}
