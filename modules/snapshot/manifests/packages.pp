class snapshot::packages {

    # pick up various users, nutcracker
    include mediawiki

    if ($::lsbdistcodename == 'precise') {
        package { [
            'subversion',
            'mysql-client-5.5',
            'p7zip-full',
            'libicu42',
            'utfnormal',
            'mwbzutils'
            ]: ensure => 'present',
        }
    }
    else {
        package { [
            'subversion',
            'mysql-client-5.1',
            'p7zip-full',
            'libicu42',
            'wikimedia-php5-utfnormal',
            ]: ensure => 'present',
        }
    }

    # want mediawiki but no running webserver
    exec { 'stop-apache-service':
        command => '/etc/init.d/apache2 stop',
        onlyif  => '/etc/init.d/apache2 status',
    }
}
