class snapshot::packages {

    # pick up various users, twemproxy
    include mediawiki

    if ($::lsbdistcodename == 'precise') {
        package { [
            'subversion',
            'php5',
            'php5-cli',
            'php5-mysql',
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
            'php5',
            'php5-cli',
            'php5-mysql',
            'mysql-client-5.1',
            'p7zip-full',
            'libicu42',
            'wikimedia-php5-utfnormal',
            ]: ensure => 'present',
        }
    }

    # want mediawiki but no running webserver
    service { 'noapache':
        ensure => 'stopped',
        name   => 'apache2',
        enable => false,
    }
}
