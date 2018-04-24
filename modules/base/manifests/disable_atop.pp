# Base::disable_atop class disables the atop service and cron,
# as it is causing issues with the latest version.
class base::disable_atop {
    service { 'atop':
        ensure => 'stopped',
    }

    file { '/etc/cron.d/atop':
        ensure => absent,
    }
}
