# Configuration files for php5 running on application servers
#
# **fatal_log_file**
# Where to send PHP fatal traces.
#
# requires mediawiki::packages to be in place
class mediawiki::config::php(
    $fatal_log_file='udp://10.64.0.21:8420'
) {

    Class['mediawiki::packages'] -> Class['mediawiki::config::php']
    Class['mediawiki::config::php'] -> Class['mediawiki::config::base']

    file { '/etc/php5/apache2/php.ini':
        owner  => root,
        group  => root,
        mode   => '0444',
        source => 'puppet:///modules/mediawiki/php/php.ini',
    }
    file { '/etc/php5/cli/php.ini':
        owner  => root,
        group  => root,
        mode   => '0444',
        source => 'puppet:///modules/mediawiki/php/php.ini.cli',
    }
    file { '/etc/php5/conf.d/fss.ini':
        owner  => root,
        group  => root,
        mode   => '0444',
        source => 'puppet:///modules/mediawiki/php/fss.ini',
    }
    file { '/etc/php5/conf.d/apc.ini':
        owner  => root,
        group  => root,
        mode   => '0444',
        source => 'puppet:///modules/mediawiki/php/apc.ini',
    }
    file { '/etc/php5/conf.d/wmerrors.ini':
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('mediawiki/php/wmerrors.ini.erb'),
    }
    file { '/etc/php5/conf.d/igbinary.ini':
        owner  => root,
        group  => root,
        mode   => '0444',
        source => 'puppet:///files/php/igbinary.ini',
    }
    file { '/etc/php5/conf.d/mail.ini':
        owner   => root,
        group   => root,
        mode    => '0444',
        source => 'puppet:///modules/mediawiki/php/mail.ini',
    }

}
