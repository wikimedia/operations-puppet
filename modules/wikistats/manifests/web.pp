# the apache setup for the wikistats site
# expects:
# class {'webserver::php5': ssl => true; }
# to be on the node already, but can be enabled if not sharing
# with other roles already using it
class wikistats::web (
    $wikistats_host,
    ) {
    # Apache site from template
    apache::site { $wikistats_host:
        content => template('wikistats/apache/wikistats.erb'),
    }

    # document root
    file { '/var/www/wikistats':
        ensure  => directory,
        mode    => '0755',
        owner   => 'wikistatsuser',
        group   => 'www-data',
    }

    include ::apache::mod::rewrite

}
