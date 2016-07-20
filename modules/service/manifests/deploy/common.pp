# === Class service::deploy::common
#
# Common resources any deployed service would need. Require this in your
# service::deploy provider
#
class service::deploy::common {
    file { '/srv/deployment':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}
