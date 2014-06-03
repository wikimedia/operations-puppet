class beta::common {
    include ::beta::config

    file { '/usr/local/apache':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }
    file { '/usr/local/apache/common-local':
        ensure  => link,
        # Link to files managed by scap
        target  => $::beta::config::scap_deploy_dir,
        require => File['/usr/local/apache'],
    }
    file { '/usr/local/apache/conf':
        ensure  => link,
        target  => '/data/project/apache/conf',
        require => File['/usr/local/apache'],
    }
    file { '/usr/local/apache/uncommon':
        ensure  => link,
        target  => '/data/project/apache/uncommon',
        require => File['/usr/local/apache'],
    }
}
