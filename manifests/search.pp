# search.pp
# vim: set noet :

# Virtual resource for the monitoring server
@monitor_group { 'lucene': description => 'eqiad search servers' }

class lucene {

    class server($indexer=false, $udplogging=true) {
        Class['lucene::packages'] -> Class['lucene::server']

        require role::lucene::configuration

        include passwords::lucene
        $lucene_oai_pass = $passwords::lucene::oai_pass

        include lucene::packages,
            lucene::service

        if $indexer == true {
            include lucene::indexer
        }

        file { '/a/search/conf/lsearch-global-2.1.conf':
            ensure  => 'present',
            require => File['/a/search/conf'],
            owner   => 'lsearch',
            group   => 'lsearch',
            mode    => '0444',
            content => template('lucene/lsearch-global-2.1.conf.erb'),
        }

        file { '/etc/lsearch.conf':
            ensure  => 'present',
            owner   => 'lsearch',
            group   => 'lsearch',
            mode    => '0444',
            content => template('lucene/lsearch.conf.erb'),
        }

        file { '/a/search/conf/lsearch.log4j':
            ensure  => 'present',
            require => File['/a/search/conf'],
            owner   => 'lsearch',
            group   => 'lsearch',
            mode    => '0444',
            content => template('lucene/lsearch.log4j.erb'),
        }

        file { [ '/a/search',
                '/a/search/indexes',
                '/a/search/log',
                '/a/search/conf',
                '/a/search/dumps'
                ]:
            ensure => 'directory',
            owner  => 'lsearch',
            group  => 'lsearch',
            mode   => '0775',
        }
        if $lucene::server::indexer == true {
            file { '/etc/logrotate.d/lucene-indexer':
                ensure => 'present',
                owner  => 'root',
                group  => 'root',
                mode   => '0444',
                source => 'puppet:///files/logrotate/search-indexer',
            }

            file { '/a/search/conf/lucene.jobs.conf':
                ensure  => 'present',
                owner   => 'root',
                group   => 'root',
                mode    => '0444',
                content => template('lucene/lucene.jobs.conf.erb'),
            }
        }

        # Conf for sync-conf-from-common cronjob
        if $::realm == 'production' {
            $sync_conf_all_dblist              = 'tin.eqiad.wmnet::common/*.dblist'
            $sync_conf_initialisesettings      = 'tin.eqiad.wmnet::common/wmf-config/InitialiseSettings.php'
            $sync_conf_initialisesettings_labs = ''
            $sync_conf_messages                = 'tin.eqiad.wmnet::common/php/languages/messages'
        } else {
            $sync_conf_all_dblist              = '/srv/mediawiki/*.dblist'
            $sync_conf_initialisesettings      = '/srv/mediawiki/wmf-config/InitialiseSettings.php'
            $sync_conf_initialisesettings_labs = '/srv/mediawiki/wmf-config/InitialiseSettings-labs.php'
            $sync_conf_messages                = '/srv/mediawiki/php-master/languages/messages'
        }
        cron { 'sync-conf-from-common':
            ## to occassionally poll for mediawiki configs
            ensure  => 'present',
            require => File['/a/search/conf'],
            command => "rsync -a --delete --exclude=**/.svn/lock --no-perms ${sync_conf_all_dblist} /a/search/conf/ && rsync -a --delete --exclude=**/.svn/lock --no-perms ${sync_conf_initialisesettings} ${sync_conf_initialisesettings_labs} /a/search/conf/ && rsync -a --delete --exclude=**/.svn/lock --no-perms ${sync_conf_messages} /a/search/conf/",
            user    => 'lsearch',
            minute  => '15',
        }

        cron { 'delete-old-logs':
            ## this is to compliment log4j's log rotation.
            ## we want to use log4j's logrotate ability,
            ## as it's easier on the system,
            ## but log4j does not yet have "delete old logs" capability :/
            ensure  => 'present',
            command =>'find /a/search/log/log.* -type f -mtime +3 -exec rm -f {} \;',
            user    => 'lsearch',
            hour    => '0',
            minute  => '0',
        }
    }

    class packages {
        package { ['oracle-j2sdk1.6', 'libudp2log-log4j-java']:
            ensure => 'latest',
        }
        package { 'liblog4j1.2-java':
            ensure  => 'latest',
            require => Package['oracle-j2sdk1.6'],
        }
        package { 'lucene-search-2':
            # Present instead of latest for controlled upgrade
            ensure  => 'present',
            require => Package['oracle-j2sdk1.6'],
        }
    }

    class service {
        service { 'lucene-search-2':
            ensure  => 'running',
            require => [ File['/etc/lsearch.conf'],
                        File['/a/search/conf/lsearch-global-2.1.conf'],
                        File['/a/search/indexes'],
                        File['/a/search/log']
                        ],
        }

        if $lucene::server::indexer == false {
            monitor_service { 'lucene':
                description   => 'Lucene',
                check_command => 'check_lucene',
                retries       => '6'
            }

            # CRITICAL for months (oldest 158d old); clearly not a serious issue
            # --faidon, 2013-11-18
            # monitor_service { 'lucene_search':
            #   description   => 'search indices - check lucene status page',
            #   check_command => 'check_lucene_frontend'
            # }
        }
    }

    class users {

        group { 'lsearch':
            ensure => present,
            name   => 'lsearch',
            system => true,
        }

        user { 'lsearch':
            name          => 'lsearch',
            gid           => 'lsearch',
            managehome    => true,
            system        => true,
            home          => '/var/lib/search',
        }
    }

    class indexer {

        include rsync::server
        rsync::server::module { 'search':
            path        => '/a/search/indexes',
            read_only   => 'yes',
            comment     => 'Lucene Search 2 index data',
        }

        file { '/a/search/conf/nooptimize.dblist':
            owner  => 'lsearch',
            group  => 'lsearch',
            mode   => '0444',
            source => 'puppet:///files/lucene/nooptimize.dblist',
        }

        file { '/a/search/lucene.jobs.sh':
            owner  => 'lsearch',
            group  => 'lsearch',
            mode   => '0755',
            source => 'puppet:///files/lucene/lucene.jobs.sh',
        }

        cron { 'snapshot':
            ensure  => 'present',
            require => File['/a/search/lucene.jobs.sh'],
            command => '/a/search/lucene.jobs.sh snapshot',
            user    => 'lsearch',
            hour    => '4',
            minute  => '30',
        }

        cron { 'snapshot-precursors':
            ensure  => 'present',
            require => File['/a/search/lucene.jobs.sh'],
            command => '/a/search/lucene.jobs.sh snapshot-precursors',
            user    => 'lsearch',
            weekday => '5',
            hour    => '9',
            minute  => '30',
        }

        cron { 'indexer-cron':
            ensure  => 'present',
            require => File['/a/search/lucene.jobs.sh'],
            command => '/a/search/lucene.jobs.sh indexer-cron',
            user    => 'lsearch',
            weekday => '6',
            hour    => '0',
            minute  => '0',
        }

        cron { 'import-private':
            ensure  => 'present',
            require => File['/a/search/lucene.jobs.sh'],
            command => '/a/search/lucene.jobs.sh import-private',
            user    => 'lsearch',
            hour    => '2',
            minute  => '0',
        }

        cron { 'import-broken':
            ensure  => 'present',
            require => File['/a/search/lucene.jobs.sh'],
            command => '/a/search/lucene.jobs.sh import-broken',
            user    => 'lsearch',
            hour    => '3',
            minute  => '0',
        }

        cron { 'build-prefix':
            ensure  => 'present',
            require => File['/a/search/lucene.jobs.sh'],
            command => '/a/search/lucene.jobs.sh build-prefix',
            user    => 'lsearch',
            hour    => '9',
            minute  => '25',
        }
    }
}

class search::searchqa::phase1 {
    file { '/opt/searchqa':
        ensure => directory,
        owner  => 'root',
        group  => 'wikidev',
        mode   => '0755'
    }
}

class search::searchqa {
    require search::searchqa::phase1
    file { '/opt/searchqa/bin':
        recurse => true,
        purge   => true,
        force   => true,
        owner   => 'root',
        group   => 'wikidev',
        mode    => '0555',
        source  => 'puppet:///files/searchqa/bin',
    }

    file { '/opt/searchqa/lib':
        recurse => true,
        purge   => true,
        force   => true,
        owner   => 'root',
        group   => 'wikidev',
        mode    => '0644',
        source  => 'puppet:///files/searchqa/lib',
    }

    file { '/opt/searchqa/data':
        ensure => 'directory',
        owner  => 'root',
        group  => 'wikidev',
        mode   => '0774',
    }
}
