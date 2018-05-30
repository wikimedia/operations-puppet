# == Class cergen
# Installs cergen package.
#
class cergen {
    package { 'cergen':
        ensure          => 'present',
        # If Jessie, we need to manually specify versions
        # of some dependencies from backports.
        install_options => ['-t', "${::lsbdistcodename}-backports"],
    }

    file { '/etc/cergen':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0750',
    }

}
