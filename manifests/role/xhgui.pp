# == Class: role::xhgui
#
# XHGUI is a MongoDB-backed PHP webapp for viewing and analyzing
# PHP profiling data.
#
class role::xhgui {
    include ::apache::mod::php5
    include ::apache::mod::rewrite

    include ::mongodb

    # TODO: set up indexing on mongodb
    # TODO: set NUMA arg

    system::role { 'role::xhgui': }

    require_package('php5-mongo')

    ferm::service { 'xhgui_mongodb':
        port   => 27017,
        proto  => 'tcp',
        srange => '$INTERNAL',
    }

    ferm::service { 'xhgui_http':
        port   => 80,
        proto  => 'tcp',
        srange => '$INTERNAL',
    }

    git::clone { 'operations/software/xhgui':
        ensure    => 'latest',
        directory => '/srv/xhgui',
        branch    => 'wmf_deploy',
    } ->

    file { '/srv/xhgui/cache':
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0755',
    } ->

    apache::site { 'xhgui_apache_site':
        content => template('apache/sites/xhgui.erb'),
    }
}
