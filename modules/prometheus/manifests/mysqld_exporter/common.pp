# Setup the common resources for all mysqld exporter resources:
# * The package installation
# * The config dir
# * The instance service (different from the package one)

class prometheus::mysqld_exporter::common {
    require_package('prometheus-mysqld-exporter')

    file { '/etc/default/prometheus':
        ensure => directory,
        mode   => '0550',
        owner  => 'prometheus',
        group  => 'prometheus',
    }

    base::service_unit { 'prometheus-mysqld-exporter@':
        ensure        => present,
        refresh       => true,
        systemd       => true,
        template_name => 'prometheus-mysqld-exporter@',
        require       => Package['prometheus-mysqld-exporter'],
    }
}
