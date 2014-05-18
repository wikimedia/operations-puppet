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
        # Create before wikimedia-task-appserver attempts
        # to create /usr/local/apache/common.
        before  => Package['wikimedia-task-appserver'],
        require => File['/usr/local/apache'],
    }
    file { '/usr/local/apache/common':
        ensure  => link,
        target  => '/usr/local/apache/common-local',
        require => File['/usr/local/apache/common-local'],
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
