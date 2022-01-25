class profile::prometheus::rabbitmq_exporter (
    String $rabbit_monitor_username = lookup('profile::prometheus::rabbit_monitor_user'),
    String $rabbit_monitor_password = lookup('profile::prometheus::rabbit_monitor_pass'),
){

    $rabbit_host = 'localhost:15672'

    file { '/etc/prometheus/':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
    }

    file { '/etc/prometheus/rabbitmq-exporter.yaml':
        ensure  => 'present',
        owner   => 'prometheus',
        group   => 'prometheus',
        mode    => '0440',
        content => template('profile/prometheus/rabbitmq-exporter.conf.erb'),
        require => File['/etc/prometheus/'],
    }

    ensure_packages('prometheus-rabbitmq-exporter')

    service { 'prometheus-rabbitmq-exporter':
        ensure  => running,
        require => File['/etc/prometheus/rabbitmq-exporter.yaml'],
    }

    profile::auto_restarts::service { 'prometheus-rabbitmq-exporter': }
}
