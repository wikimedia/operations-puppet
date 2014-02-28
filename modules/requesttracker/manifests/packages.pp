# installs required packages for Request Tracker
# changed from 'latest' to 'present' to avoid
# surprise upgrades

class requesttracker::packages {

    package { 'request-tracker4':
        ensure => 'latest',
    }

    package { 'rt4-db-mysql':
        ensure => 'latest',
    }

    package { 'rt4-clients':
        ensure => 'latest',
    }

    package { 'libdbd-pg-perl':
        ensure => 'latest',
    }
}

