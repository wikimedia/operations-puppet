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
        }
        'production': {
            $racktables_host = 'racktables.wikimedia.org'
        }
        'default': {
            fail('unknown realm, should be labs or production')
        }
    }

    apache::site { 'racktables.wikimedia.org':
        content => template('apache/sites/racktables.wikimedia.org.erb'),
    }

    apache::conf { 'namevirtualhost':
        source => 'puppet:///files/apache/conf.d/namevirtualhost',
    }

    include ::apache::mod::rewrite
    include ::apache::mod::headers

    ferm::service { 'racktables-http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'racktables-https':
        proto => 'tcp',
        port  => '443',
    }

}
