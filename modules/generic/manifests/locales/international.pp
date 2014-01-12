# this installs a bunch of international locales, f.e. for "planet" on singer
class generic::locales::international {

    package { 'locales':
        ensure => latest,
    }

    file { '/var/lib/locales/supported.d/local':
        source => 'puppet:///modules/generic/locales/local_int',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    exec { '/usr/sbin/locale-gen':
        subscribe   => File['/var/lib/locales/supported.d/local'],
        refreshonly => true,
        require     => File['/var/lib/locales/supported.d/local'],
    }
}
