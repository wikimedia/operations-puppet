class beta::common {
    include ::beta::config

    file { '/usr/local/apache/conf':
        ensure  => link,
        target  => '/data/project/apache/conf',
    }
    file { '/usr/local/apache/uncommon':
        ensure  => link,
        target  => '/data/project/apache/uncommon',
    }
}
