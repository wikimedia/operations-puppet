class releases::mini_dinstall (
    $keyid,
) {
    $root_dir = '/srv/org/wikimedia/mini-dinstall'
    $archive_dir = '/srv/org/wikimedia/releases/debian'
    $owner = 'mini-dinstall'
    $group = 'mwupld'

    generic::systemuser { $owner:
        name => $owner,
        home => $root_dir,
        before => Class['mini_dinstall'],
    }

    sudo_group { $group:
        privileges => ["ALL = ($owner) NOPASSWD: mini-dinstall"],
    }

    file { "${root_dir}/.gnupg":
        ensure => 'directory',
        owner => $owner,
        group => $group,
        mode => '0700',
    }

    file { "${root_dir}/.gnupg/secring.gpg":
        ensure => 'present',
        source => 'puppet:///private/gpg/mini_dinstall/secring.gpg',
        owner => $owner,
        group => $group,
        mode => '0600',
    }

    file { "${root_dir}/.gnupg/pubring.gpg":
        ensure => 'present',
        source => 'puppet:///private/gpg/mini_dinstall/pubring.gpg',
        owner => $owner,
        group => $group,
        mode => '0600',
    }

    class { 'mini_dinstall':
        root_dir => $root_dir,
        archive_dir => $archive_dir,
        owner => $owner,
        group => $group,
        keyid => $keyid,
    }
}
