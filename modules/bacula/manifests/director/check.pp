# Class that installs the check script and all needed
# dependencies to run it, but does nothing else
class bacula::director::check {
    ensure_packages('python3-prometheus-client')

    file { '/usr/bin/check_bacula.py':
        ensure => absent,
    }

    nrpe::plugin { 'check_bacula':
        source => 'puppet:///modules/bacula/check_bacula.py',
    }
}
