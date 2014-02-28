# installs required packages for Request Tracker
# changed from 'latest' to 'present' to avoid
# surprise upgrades

class requesttracker::packages {

    package { 'request-tracker4':
        ensure => 'present',
    }

    package { 'rt4-db-mysql':
        ensure => 'present',
    }

    package { 'rt4-clients':
        ensure => 'present',
    }

    package { 'libdbd-pg-perl':
        ensure => 'present',
    }
}

