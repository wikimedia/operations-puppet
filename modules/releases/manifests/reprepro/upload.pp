class releases::reprepro::upload (
    String $private_key  = 'releases/id_rsa.upload',
    String $user         = 'releases',
    String $group        = 'releases',
    String $sudo_user    = '%wikidev',
    Stdlib::Unixpath $homedir      = '/var/lib/releases',
    Optional[String] $upload_host  = undef,
) {
    group { 'releases':
        ensure => present,
        name   => $group,
    }

    user { 'releases':
        ensure     => present,
        name       => $user,
        home       => $homedir,
        shell      => '/bin/false',
        comment    => 'Releases user',
        gid        => $group,
        managehome => true,
        require    => Group['releases'],
    }

    file { "${homedir}/.ssh":
        ensure  => directory,
        owner   => $user,
        group   => $group,
        mode    => '0700',
        require => User['releases'],
    }

    file { "${homedir}/.ssh/id_rsa.${upload_host}":
        ensure    => file,
        owner     => $user,
        group     => $group,
        mode      => '0600',
        require   => User['releases'],
        content   => secret($private_key),
        show_diff => false,
    }

    file { "${homedir}/.ssh/config":
        ensure  => file,
        owner   => $user,
        group   => $group,
        mode    => '0600',
        require => User['releases'],
        content => template('releases/ssh_config.erb'),
    }

    file { "${homedir}/.dput.cf":
        ensure  => file,
        owner   => $user,
        group   => $group,
        mode    => '0600',
        require => User['releases'],
        content => template('releases/dput.erb'),
    }

    file { '/usr/local/bin/deb-upload':
        ensure  => file,
        owner   => $user,
        group   => $group,
        mode    => '0555',
        require => User['releases'],
        source  => 'puppet:///modules/releases/deb-upload',
    }

    package { 'dput':
        before => File['/usr/local/bin/deb-upload'],
    }

    sudo::user { 'releases_dput':
        user       => $sudo_user,
        privileges => ["ALL = (${user}) NOPASSWD: /usr/bin/dput"],
    }

    # T83213
    package { 'unzip':
        ensure => 'present',
    }
}
