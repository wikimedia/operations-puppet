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
            $host          = '10.64.16.149' # graphite1004
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

        # The prerm script in the packages for jessie and stretch is broken:
        # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=910787
        # Clean this up via puppet as we're deprecating Diamond anyway
        exec { 'cleanup_diamond_state':
            command => '/bin/systemctl reset-failed diamond',
            onlyif  => '/bin/systemctl list-units --failed | grep --quiet diamond.service',
            require => Package['diamond'],
        }

        base::service_auto_restart { 'diamond':
            ensure => absent,
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

        base::service_auto_restart { 'diamond': }
    }
}
