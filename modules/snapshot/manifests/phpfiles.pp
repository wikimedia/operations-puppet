class snapshot::phpfiles {
    require snapshot::packages

    if ($::lsbdistcodename == 'lucid') {
        file { 'snapshot-php5-cli-ini':
            ensure => 'present',
            path   => '/etc/php5/cli/php.ini',
            mode   => '0644',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/snapshot/php.ini.cli.snaps.lucid',
        }

        file { 'snapshot-fss-ini':
            ensure => 'present',
            path   => '/etc/php5/conf.d/fss.ini',
            mode   => '0644',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/snapshot/fss.ini.snaps.lucid',
        }
    }

}
