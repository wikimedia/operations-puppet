class puppetception(
    $git_url,
) {
    include ::role::labs::lvm::srv
    $install_directory = "/srv/puppetception/git"

    file { $install_directory:
        recurse => true,
        owner   => 'root',
        group   => 'root',
        ensure  => directory,
        require => Mount['/srv'],
    }

    git::clone { $install_directory:
        directory => $install_directory,
        origin    => $git_url,
        ensure    => latest,
        require   => File[$install_directory],
    }

    file { "/sbin/puppetception":
        source  => template('puppetception/puppetception.erb'),
        ensure => present,
        mode   => '0700',
        owner  => 'root',
        group  => 'root',
    }
}
