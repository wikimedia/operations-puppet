# == Class dashiki
# Sets up dashiki.
# To build a dashboard and host it, use the dashiki::instance define.
#
# NOTE: This just clones dashiki.  You must install dependencies yourself.
#
# == Parameters
# $var_directory  - path to Dashiki var directory.  This will also be the dashiki user's home directory.  Default: /var/lib/dashiki
# $log_directory  - path to Dashiki server logs.  Default: /var/log/dashiki
#
class dashiki(
    $var_directory  = '/var/lib/dashiki/dist',
    $log_directory  = '/var/log/dashiki',
){
    $root_directory = '/usr/local/share/dashiki',
    $user           = 'dashiki'
    $group          = 'dashiki'

    # Make sure nodejs is installed.
    require_package('nodejs')

    group { $group:
        ensure => present,
        system => true,
    }

    user { $user:
        ensure     => present,
        gid        => $group,
        home       => $root_directory,
        managehome => false,
        system     => true,
        require    => Group[$group],
    }

    # dashiki source and build directory
    # Instances are built to and served from
    # $root_directory/dist/$layout-$wikiConfig
    file { $root_directory:
        ensure  => directory,
        owner   => $user,
        group   => $group,
        mode    => '0755',
        require => [User[$user], Group[$group]],
    }

    # Default dashiki log directory.
    # Instances will log to
    # $log_directory/dashiki-$layout-$wikiConfig.log
    file { $log_directory:
        ensure  => directory,
        owner   => $user,
        group   => $group,
        mode    => '0755',
        require => [User[$user], Group[$group]],
    }
}
