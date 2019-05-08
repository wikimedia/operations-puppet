# Make /etc/init/mysql managed by puppet. This allows us to make quick
# changes to harden the wrapper without rebuilding the custom wmf-mariadb10
# package
# Once all jessies with 10.0 are gone, we can hopefully
# discard init.d in favour of the package systemd service unit
#
# Default behavior is for the service to be unmanaged and manually
# started/stopped.
# It is important to keep this like this for all production services (if
# mysql and replication start automatically and there has been a crash
# or an upgrade (hardware or software), data will get corrupted).
# However, for non critical services (beta, other small, non-dedicated
# services, we allow mysql to auto-start.
# With $manage = true this class will set $ensure and $enabled as specified.

class mariadb::service (
    $package  = 'undefined',
    $basedir  = 'undefined',
    $manage   = false,
    $ensure   = stopped,
    $enable   = false,
    $override = false,
    ) {

    # default strech to mariadb 10.1, others to 10.0
    if os_version('debian >= stretch') and $package == 'undefined' {
        $installed_package = 'wmf-mariadb101'
    } elsif $package == 'undefined' {
        $installed_package = 'wmf-mariadb10'
    } else {
        $installed_package = $package
    }

    # mariadb 10.1 and later use systemd, others use init.d
    # Also identify vendor

    case $installed_package {
        'wmf-mariadb', 'wmf-mariadb10': {
            $systemd = false
            $vendor  = 'mariadb'
        }
        'wmf-mariadb101', 'wmf-mariadb102', 'wmf-mariadb103': {
            $systemd = true
            $vendor  = 'mariadb'
        }
        'wmf-mysql57', 'wmf-mysql80': {
            $systemd = true
            $vendor = 'mysql'
        }
        'wmf-mysql56': {
            $systemd = false
            $vendor = 'mysql'
        }
        default: {
            fail("Invalid package version \"${installed_package}\". \
The only allowed versions are: wmf-mariadb10, wmf-mariadb101, wmf-mariadb102, \
wmf-mariadb103, wmf-mysql57 or wmf-mysql80")
        }
    }

    if $systemd {
        # TODO: use the base::service configuration
        if $manage {
            service { $vendor:
                # $manage assumes only the main instance is managed-
                # multiple instances have to be managed manually
                ensure => $ensure,
                enable => $enable,
            }
        }
        # handle per-host special configuration
        if $override {
            file { "/etc/systemd/system/${vendor}.service.d":
                ensure => directory,
                mode   => '0755',
                owner  => 'root',
                group  => 'root',
            }
            file { "/etc/systemd/system/${vendor}.service.d/override.conf":
                ensure  => present,
                mode    => '0755',
                owner   => 'root',
                group   => 'root',
                content => $override,
                notify  => Exec['systemctl-daemon-reload'],
            }
            exec { 'systemctl-daemon-reload':
                command     => '/bin/systemctl daemon-reload',
                refreshonly => true,
            }
        } else {
            file { "/etc/systemd/system/${vendor}.service.d/override.conf":
                ensure => absent,
                notify => File["/etc/systemd/system/${vendor}.service.d"]
            }
            file { "/etc/systemd/system/${vendor}.service.d":
                ensure => absent,
            }
        }

    } else {
        # using still init.d
        if $basedir == 'undefined' {
            $initd_basedir = "/opt/${installed_package}"
        } else {
            $initd_basedir = $basedir
        }

        file { "${initd_basedir}/service":
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            content => template('mariadb/mariadb.server.erb'),
            require => Package[$installed_package],
        }

        file { '/etc/init.d/mysql':
            ensure  => 'link',
            target  => "${initd_basedir}/service",
            require => File["${initd_basedir}/service"],
        }

        file { '/etc/init.d/mariadb':
            ensure  => 'link',
            target  => "${initd_basedir}/service",
            require => File["${initd_basedir}/service"],
        }

        if $manage {
            service { 'mysql':
                ensure  => $ensure,
                enable  => $enable,
                require => File['/etc/init.d/mysql'],
            }
        }
    }
}
