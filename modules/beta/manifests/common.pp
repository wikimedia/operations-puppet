class beta::common {
    include ::beta::config

    file { '/usr/local/apache/common-local':
        ensure  => link,
        # Link to files managed by scap
        target  => $::beta::config::scap_deploy_dir,
    }
    file { '/usr/local/apache/conf':
        ensure  => link,
        target  => '/data/project/apache/conf',
        before => Exec['sync_apache_config'],
    }
    file { '/usr/local/apache/uncommon':
        ensure  => link,
        target  => '/data/project/apache/uncommon',
    }
}
