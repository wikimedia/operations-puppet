class mediawiki::php {
    include ::mediawiki::packages

    file { '/etc/php5/apache2/php.ini':
        source  => 'puppet:///modules/mediawiki/php/php.ini',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['php5-common'],
    }

    file { '/etc/php5/cli/php.ini':
        source  => 'puppet:///modules/mediawiki/php/php.ini.cli',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['php5-cli'],
    }

    file { '/etc/php5/conf.d/fss.ini':
        source  => 'puppet:///modules/mediawiki/php/fss.ini',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['php5-fss'],
    }

    file { '/etc/php5/conf.d/apc.ini':
        source  => 'puppet:///modules/mediawiki/php/apc.ini',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['php-apc'],
    }

    file { '/etc/php5/conf.d/mail.ini':
        ensure  => absent,
        require => Package['php-mail'],
    }

    if ubuntu_version('precise') {
        file { '/etc/php5/conf.d/igbinary.ini':
            source  => 'puppet:///modules/mediawiki/php/igbinary.ini',
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            require => Package['php5-igbinary'],
        }

        file { '/etc/php5/conf.d/wmerrors.ini':
            source  => 'puppet:///modules/mediawiki/php/wmerrors.ini',
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            require => Package['php5-wmerrors'],
        }
    }
}
