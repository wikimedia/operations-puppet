# == Class: mediawiki::php7
#
# Packages and .ini files for PHP7 extensions.
#
class mediawiki::php7 {
    $php_module_conf_dir = '/etc/php7/mods-available'
    mediawiki::php_enmod { ['mail']: }

    # need to check if another package does this for us
    file { '/etc/php7/apache2':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    file { '/etc/php7/apache2/php.ini':
        source => 'puppet:///modules/mediawiki/php7/php.ini',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    file { '/etc/php7/cli/php.ini':
        source => 'puppet:///modules/mediawiki/php/php.ini.cli',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    file { "${php_module_conf_dir}/mail.ini":
        ensure => absent,
    }
}
