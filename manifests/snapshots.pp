class snapshots::packages {

    # pick up various users, twemproxy
    include mediawiki

    if ($::lsbdistcodename == 'precise') {
        package { [ 'subversion',
                    'php5',
                    'php5-cli',
                    'php5-mysql',
                    'mysql-client-5.5',
                    'p7zip-full',
                    'libicu42',
                    'utfnormal',
                    'mwbzutils'
        ]:
            ensure => 'present',
        }
    }
    else {
        package { [ 'subversion',
                    'php5',
                    'php5-cli',
                    'php5-mysql',
                    'mysql-client-5.1',
                    'p7zip-full',
                    'libicu42',
                    'wikimedia-php5-utfnormal'
        ]:
            ensure => 'present',
        }
    }
}

class snapshots::files {
    require snapshots::packages

    if ($::lsbdistcodename != 'precise') {
        file { 'snapshot-php5-cli-ini':
            ensure => 'present',
            path   => '/etc/php5/cli/php.ini',
            mode   => '0644',
            owner  => 'root',
            group  => 'root',
            source => "puppet:///files/php/php.ini.cli.snaps.${::lsbdistcodename}",
        }

        file { 'snapshot-fss-ini':
            ensure => 'present',
            path   => '/etc/php5/conf.d/fss.ini',
            mode   => '0644',
            owner  => 'root',
            group  => 'root',
            source => "puppet:///files/php/fss.ini.snaps.${::lsbdistcodename}",
        }
    }

}

class snapshots::sync {
    require snapshots::packages

        exec { 'snapshot-trigger-mw-sync':
            command => '/bin/true',
            notify  => Exec['mw-sync'],
            unless  => '/usr/bin/test -d /usr/local/apache/common-local',
        }
}

class snapshots::noapache {
    service { 'noapache':
        ensure => 'stopped',
        name   => 'apache2',
        enable => false,
    }
}

