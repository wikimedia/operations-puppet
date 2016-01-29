class releases::reprepro::upload (
    # lint:ignore:puppet_url_without_modules
    $private_key  = 'puppet:///private/releases/id_rsa.upload',
    # lint:endignore
    $user         = 'releases',
    $group        = 'releases',
    $sudo_user    = '%wikidev',
    $homedir      = '/var/lib/releases',
    $upload_host  = 'bromine.eqiad.wmnet',
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
        ensure  => file,
        owner   => $user,
        group   => $group,
        mode    => '0600',
        require => User['releases'],
        source  => $private_key,
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
