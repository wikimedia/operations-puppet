# == Class cergen
# Installs cergen package.
#
class cergen {
    package { 'cergen':
        ensure => 'present',
    }
    file { '/etc/cergen':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0750',
    }
}
