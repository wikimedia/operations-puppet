# sets up needed directories for a planet (rawdog) install
class planet::dirs {


    file { [
        '/var/www/planet',
        '/var/log/planet',
        '/etc/rawdog/',
        '/etc/rawdog/theme',
        '/etc/rawdog/theme/wikimedia',
        ]:
        ensure => 'directory',
        owner  => 'planet',
        group  => 'planet',
        mode   => '0755',
    }

    file { '/etc/rawdog/plugins':
        ensure => directory,
        owner  => 'planet',
        group  => 'planet',
        mode   => '0755',
    }

    file { '/etc/rawdog/config':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'planet',
        group   => 'planet',
        content => template('planet/feeds/global.erb'),
    }
}
