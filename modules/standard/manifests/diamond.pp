# standard class for diamond
class standard::diamond {

    case $::realm {
        'labs': {
            $host          = '10.64.37.13' # labmon1001
            $port          = '2003'
            # Prefix labs metrics with project name
            $path_prefix   = $::labsproject
            $keep_logs_for = '0' # Current day only
            $service       = true
        }
        default: {
            $host          = '10.64.32.155' # graphite1001
            $port          = '2003'
            $path_prefix   = 'servers'
            $keep_logs_for = '5'
            $service       = true
        }
    }

    if hiera('diamond::remove', false) { # lint:ignore:wmf_styleguide
        package { ['diamond', 'python-diamond']:
            ensure => purged,
        }

        file { '/etc/diamond/diamond.conf':
            ensure => absent,
        }

        if os_version('debian >= jessie') {
            base::service_auto_restart { 'diamond':
                ensure => absent,
            }
        }
    }
    else {
        class { '::diamond':
            path_prefix   => $path_prefix,
            keep_logs_for => $keep_logs_for,
            service       => $service,
            settings      => {
                # lint:ignore:quoted_booleans
                # Diamond needs its bools in string-literals.
                enabled => 'true',
                # lint:endignore
                host    => $host,
                port    => $port,
                batch   => '20',
            },
        }

        if os_version('debian >= jessie') {
            base::service_auto_restart { 'diamond': }
        }
    }
}
