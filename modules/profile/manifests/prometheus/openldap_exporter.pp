# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::openldap_exporter (
    String $monitor_pass = lookup('profile::prometheus::openldap_exporter::monitor_pass')
){

    package { 'prometheus-openldap-exporter':
        ensure => present,
    }

    file { '/etc/prometheus/openldap-exporter.yaml':
        ensure  => present,
        mode    => '0440',
        owner   => 'prometheus',
        group   => 'prometheus',
        content => template('profile/prometheus/prometheus.conf.erb'),
        notify  => Service['prometheus-openldap-exporter'],
    }

    service { 'prometheus-openldap-exporter':
        ensure  => running,
        require => File['/etc/prometheus/openldap-exporter.yaml'],
    }

    profile::auto_restarts::service { 'prometheus-openldap-exporter': }
}
