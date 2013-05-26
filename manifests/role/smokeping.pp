# https://smokeping.wikimedia.org

class role::smokeping {

    system_role { 'role::smokeping': description => 'Smokeping' }

    include standard-noexim, webserver::php5-gd,
    misc::smokeping

    if ! defined(Class['webserver::php5']) {
        class {'webserver::php5': ssl => true; }
    }

    # be flexible about labs vs. prod
    case $::realm {
        labs: {
            $smokeping_host = "${role::smokeping::instancename}.${role::smokeping::domain}"
            $smokeping_ssl_cert = '/etc/ssl/certs/star.wmflabs.pem'
            $smokeping_ssl_key = '/etc/ssl/private/star.wmflabs.key'
            install_certificate{ 'star.wmflabs.org': }
        }
        production: {
            $smokeping_host = 'smokeping.wikimedia.org'
            $smokeping_ssl_cert = '/etc/ssl/certs/star.wikimedia.org.pem'
            $smokeping_ssl_key = '/etc/ssl/private/star.wikimedia.org.key'
            install_certificate{ 'star.wikimedia.org': }
        }
        default: {
            fail('unknown realm, should be labs or production')
        }
    }


    file {
        "etc/apache2/sites-available/${smokeping_host}":
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        notify  => Service['apache2'],
        content => template('apache/sites/smokeping.wikimedia.org.erb');
    }

    file {
        '/srv/org/wikimedia/smokeping':
        ensure  => 'directory',
        mode    => '0775',
        owner   => 'root',
        group   => 'root',
    }

    file {
        '/srv/org/wikimedia/smokeping/index.cgi':
        ensure  => 'link',
        target  => '/usr/lib/cgi-bin/smokeping.cgi',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
    }

    apache_site { 'smokeping': name => $smokeping_host }
    apache_confd {'namevirtualhost': install => true, name => 'namevirtualhost'}

}
