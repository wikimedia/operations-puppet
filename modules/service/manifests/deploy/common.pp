# Common resources any deployed service would need

class service::deploy::common {
    file { '/srv/deployment':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
