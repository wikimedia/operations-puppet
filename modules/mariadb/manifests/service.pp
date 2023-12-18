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
    Boolean $manage                 = false,
    Stdlib::Ensure::Service $ensure = stopped,
    Wmflib::Enable_Service $enable  = false,
    Optional[String] $override      = undef,
) {

    # TODO: use the base::service configuration
    if $manage {
        service { 'mariadb':
            # $manage assumes only the main instance is managed-
            # multiple instances have to be managed manually
            ensure => $ensure,
            enable => $enable,
        }
    }
    # handle per-host special configuration
    if $override {
        file { '/etc/systemd/system/mariadb.service.d':
            ensure => directory,
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
        }
        file { '/etc/systemd/system/mariadb.service.d/override.conf':
            ensure  => present,
            mode    => '0644',
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
        file { '/etc/systemd/system/mariadb.service.d/override.conf':
            ensure => absent,
            notify => File['/etc/systemd/system/mariadb.service.d']
        }
        file { '/etc/systemd/system/mariadb.service.d':
            ensure => absent,
        }
    }
}
