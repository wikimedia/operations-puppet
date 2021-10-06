# Setup the common resources for all mysqld exporter resources:
# * The package installation
# * The config dir
# * The instance service (different from the package one)

class prometheus::mysqld_exporter::common {
    ensure_packages('prometheus-mysqld-exporter')

    file { '/etc/default/prometheus':
        ensure => directory,
        mode   => '0550',
        owner  => 'prometheus',
        group  => 'prometheus',
    }

    systemd::unit { 'prometheus-mysqld-exporter@':
        ensure  => present,
        content => systemd_template('prometheus-mysqld-exporter@'),
        require => Package['prometheus-mysqld-exporter'],
    }
}
