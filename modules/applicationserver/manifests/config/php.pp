# Configuration files for php5 running on application servers
#
# **fatal_log_file**
# Where to send PHP fatal traces.
#
# requires applicationserver::packages to be in place
class applicationserver::config::php(
    $fatal_log_file='udp://10.64.0.21:8420'
) {

    Class['applicationserver::packages'] -> Class['applicationserver::config::php']
    Class['applicationserver::config::php'] -> Class['applicationserver::config::base']

    file { '/etc/php5/apache2/php.ini':
        owner  => root,
        group  => root,
        mode   => '0444',
        source => 'puppet:///modules/applicationserver/php/php.ini',
    }
    file { '/etc/php5/cli/php.ini':
        owner  => root,
        group  => root,
        mode   => '0444',
        source => 'puppet:///modules/applicationserver/php/php.ini.cli',
    }
    file { '/etc/php5/conf.d/fss.ini':
        owner  => root,
        group  => root,
        mode   => '0444',
        source => 'puppet:///modules/applicationserver/php/fss.ini',
    }
    file { '/etc/php5/conf.d/apc.ini':
        owner  => root,
        group  => root,
        mode   => '0444',
        source => 'puppet:///modules/applicationserver/php/apc.ini',
    }
    file { '/etc/php5/conf.d/wmerrors.ini':
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('applicationserver/php/wmerrors.ini.erb'),
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
        content => "
// Force the envelope sender address to empty, since we don't want to receive bounces
mail.force_extra_parameters=\"-f <>\"
";
    }

}
