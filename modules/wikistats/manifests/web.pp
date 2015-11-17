# the apache setup for the wikistats site
class wikistats::web (
    $wikistats_host,
    ) {
    # Apache site from template
    apache::site { $wikistats_host:
        content => template('wikistats/apache/wikistats.erb'),
    }

    # document root
    file { '/var/www/wikistats':
        ensure => directory,
        mode   => '0755',
        owner  => 'wikistatsuser',
        group  => 'www-data',
    }

    include ::apache::mod::rewrite

}
