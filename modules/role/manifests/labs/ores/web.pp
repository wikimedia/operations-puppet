class role::labs::ores::web {
    include ::ores::web
    include ::role::labs::ores::redisproxy

    file { '/srv/log':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        before => File['/srv/log/ores'],
    }

}
