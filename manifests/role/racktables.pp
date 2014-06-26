# https://racktables.wikimedia.org

## Please note that Racktables is a tarball extraction based installation
## into its web directory root.  This means that puppet cannot fully automate
## the installation at this time & the actual tarball must be downloaded from
## http://racktables.org/ and unzipped into /srv/org/wikimedia/racktables

class role::racktables {

    system::role { 'role::racktables': description => 'Racktables' }

    include standard-noexim, webserver::php5-gd,
    webserver::php5-mysql,
    misc::racktables

    if ! defined(Class['webserver::php5']) {
        class {'webserver::php5': ssl => true; }
    }

    # be flexible about labs vs. prod
    case $::realm {
        'labs': {
            $racktables_host = "${instancename}.${domain}"
            $racktables_ssl_cert = '/etc/ssl/certs/star.wmflabs.pem'
            $racktables_ssl_key = '/etc/ssl/private/star.wmflabs.key'
            install_certificate{ 'star.wmflabs.org': }
        }
        'production': {
            $racktables_host = 'racktables.wikimedia.org'
            $racktables_ssl_cert = '/etc/ssl/certs/racktables.wikimedia.org.pem'
            $racktables_ssl_key = '/etc/ssl/private/racktables.wikimedia.org.key'
            install_certificate{ 'racktables.wikimedia.org': }
        }
        'default': {
            fail('unknown realm, should be labs or production')
        }
    }

    file {
        "/etc/apache2/sites-enabled/${racktables_host}":
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        notify  => Service['apache2'],
        content => template('apache/sites/racktables.wikimedia.org.erb');
    }

    file { '/etc/apache2/conf.d/namevirtualhost':
        source => 'puppet:///files/apache/conf.d/namevirtualhost',
        mode   => '0444',
        notify => Service['apache2'],
    }

    include ::apache::mod::rewrite

    ferm::service { 'racktables-http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'racktables-https':
        proto => 'tcp',
        port  => '443',
    }

}
