# Housekeeping class used to clean up after the transition
# role::parsoid::production => role::parsoid
class role::parsoid::transition_cleanup {
    file { ['/usr/bin/parsoid', '/etc/default/parsoid']:
        ensure => absent,
    }

    cron { 'parsoid-hourly-logrot':
        ensure => absent,
    }

    system::role{ 'role::parsoid::production':
        ensure => absent,
    }

    # Warning: /var/lib/parsoid will need to be cleaned by hand
    # Warning: /var/log/parsoid too, once logs are not relevant anymore.
}
