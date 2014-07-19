class puppetception(
    $git_url,
    $git_branch='master',
    $puppet_subdir = '',
) {
    include ::role::labs::lvm::srv

    $base_dir = '/srv/puppetception'
    $install_dir = "$base_dir/git"
    $puppet_dir = "${base_dir}${puppet_subdir}"
    file { [$base_dir,
            $install_dir,
            $puppet_dir
    ]:
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
