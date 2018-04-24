# Base::disable_top class disables the atop service and cron
# As it is causing issues with the latest version
class ::base::disable_atop {
    service { 'atop':
        ensure => 'stopped',
    }

    file { '/etc/cron.d/atop':
        ensure => absent,
    }
}
