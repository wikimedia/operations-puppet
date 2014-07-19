class puppetception(
    $git_url,
) {
    include ::role::labs::lvm::srv
    $install_directory = "/srv/puppetception/"
    $puppet_directory = "$install_directory/puppet"

    file { [$install_directory,
            $puppet_directory]:
        owner   => 'root',
        group   => 'root',
        ensure  => directory,
        require => Mount['/srv'],
    }

    git::clone { $puppet_directory:
        directory => $install_directory,
        origin    => $git_url,
        ensure    => latest,
        require   => File[$puppet_directory],
    }

    file { "/sbin/puppetception":
        content  => template('puppetception/puppetception.erb'),
        ensure => present,
        mode   => '0700',
        owner  => 'root',
        group  => 'root',
    }
}
