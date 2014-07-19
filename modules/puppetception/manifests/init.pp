class puppetception(
    $git_url,
    $git_branch='master',
    $install_directory = '/srv/puppetception',
    $puppet_directory = '/srv/puppetception/puppet',
) {
    include ::role::labs::lvm::srv

    file { [$install_directory,
            $puppet_directory]:
        owner   => 'root',
        group   => 'root',
        ensure  => directory,
        require => Mount['/srv'],
    }

    git::clone { $puppet_directory:
        directory => $puppet_directory,
        origin    => $git_url,
        ensure    => latest,
        require   => File[$puppet_directory],
        branch    => $git_branch,
    }

    file { "/sbin/puppetception":
        content  => template('puppetception/puppetception.erb'),
        ensure => present,
        mode   => '0700',
        owner  => 'root',
        group  => 'root',
    }
}
