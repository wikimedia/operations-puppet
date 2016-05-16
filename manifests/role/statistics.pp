class role::statistics {
    # Manually set a list of statistics servers.
    $statistics_servers = hiera(
        'statistics_servers',
        [
            'stat1001.eqiad.wmnet',
            'stat1002.eqiad.wmnet',
            'stat1003.eqiad.wmnet',
            'analytics1027.eqiad.wmnet',
        ]
    )

    # we are attempting to stop using /a and to start using
    # /srv instead.  stat1002 still use
    # /a by default.  # stat1001 and stat1003 use /srv.
    $working_path = $::hostname ? {
        'stat1001' => '/srv',
        'stat1003' => '/srv',
        default    => '/a',
    }

    class { '::statistics':
        servers      => $statistics_servers,
        working_path => $working_path,
    }

    # Allow rsyncd traffic from internal networks.
    # and stat* public IPs.
    ferm::service { 'rsync':
        proto  => 'tcp',
        port   => '873',
        srange => '($INTERNAL)',
    }

    # Set umask for wikidev users so that newly-created files are g+w
    file { '/etc/profile.d/umask-wikidev.sh':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/role/deployment/umask-wikidev-profile-d.sh',
    }
}


# (stat1003)
class role::statistics::cruncher inherits role::statistics {
    system::role { 'role::statistics::cruncher':
        description => 'Statistics general compute node (non private data)'
    }

    include standard
    include base::firewall
    include role::backup::host
    backup::set { 'home' : }

    # include stuff common to statistics compute nodes
    include statistics::compute

    # Aaron Halfaker (halfak) wants MongoDB for his project.
    class { 'mongodb':
        dbpath  => "${::statistics::working_path}/mongodb",
    }

    # rsync logs from logging hosts
    include statistics::rsync::eventlogging


    # geowiki: bringing data from production slave db to research db
    include geowiki::job::data
    # geowiki: generate limn files from research db and push them
    include geowiki::job::limn
    # geowiki: monitors the geowiki files of http://gp.wmflabs.org/
    include geowiki::job::monitoring


    # Set up reportupdater to be executed on this machine
    # and rsync the output base path to stat1001.
    class { 'reportupdater':
        base_path => "${::statistics::working_path}/reportupdater",
        user      => $::statistics::user::username,
        rsync_to  => 'stat1001.eqiad.wmnet::www/limn-public-data/',
    }

    # Set up various jobs to be executed by reportupdater
    # creating several reports on mysql research db.
    reportupdater::job { 'mobile':
        repository => 'limn-mobile-data',
        output_dir => 'mobile/datafiles',
    }
    reportupdater::job { 'flow':
        repository => 'limn-flow-data',
        output_dir =>  'flow/datafiles',
    }
    reportupdater::job { 'flow-beta-features':
        repository => 'limn-flow-data',
        output_dir =>  'metrics/beta-feature-enables',
    }
    reportupdater::job { 'edit':
        repository => 'limn-edit-data',
        output_dir => 'metrics',
    }
    reportupdater::job { 'language':
        repository => 'limn-language-data',
        output_dir => 'metrics/beta-feature-enables',
    }
    reportupdater::job { 'extdist':
        repository => 'limn-extdist-data',
        output_dir => 'extdist/datafiles',
    }
    reportupdater::job { 'ee':
        repository => 'limn-ee-data',
        output_dir => 'metrics/echo',
    }
    reportupdater::job { 'ee-beta-features':
        repository => 'limn-ee-data',
        output_dir => 'metrics/beta-feature-enables',
    }
    reportupdater::job { 'multimedia':
        repository => 'limn-multimedia-data',
        output_dir => 'metrics/beta-feature-enables',
    }
}


# (stat1002)
class role::statistics::private inherits role::statistics {
    system::role { 'role::statistics::private':
        description => 'Statistics private data host and general compute node'
    }

    include role::backup::host
    backup::set { 'home' : }

    # include stuff common to statistics compute nodes
    include statistics::compute

    # wikistats code is run here to
    # generate stats.wikimedia.org data
    include statistics::wikistats

    # rsync webrequest logs from logging hosts
    include statistics::rsync::webrequest

    # rsync mediawiki logs from logging hosts
    include statistics::rsync::mediawiki

    # eventlogging logs are not private, but they
    # are here for convenience
    include statistics::rsync::eventlogging
    # backup eventlogging logs
    backup::set { 'a-eventlogging' : }

    # kafkatee is useful here for adhoc processing of kafkadata
    require_package('kafkatee')

    # Although it is in the "private" role, the dataset actually isn't
    # private. We just keep it here to spare adding a separate role.
    include statistics::aggregator::projectview

    include passwords::mysql::research
    # This file will render at
    # /etc/mysql/conf.d/statistics-private-client.cnf.
    # This is so that users in the statistics-privatedata-users
    # group who want to access the research slave dbs do not
    # have to be in the research group, which is not included
    # in the private role (stat1002).
    mysql::config::client { 'statistics-private':
        user  => $::passwords::mysql::research::user,
        pass  => $::passwords::mysql::research::pass,
        group => 'statistics-privatedata-users',
        mode  => '0440',
    }

    # Set up reportupdater to be executed on this machine.
    # Reportupdater on stat1002 launches Hadoop jobs, and
    # the 'hdfs' user is the only 'system' user that has
    # access to required files in Hadoop.
    class { 'reportupdater':
        base_path => "${::statistics::working_path}/reportupdater",
        rsync_to  => 'stat1001.eqiad.wmnet::www/limn-public-data/metrics/',
        user      => 'hdfs',
        # We know that this is included on stat1002, but unfortunetly
        # it is done so outside of this role.  Perhaps
        # reportupdater should have its own role!
        require   => Class['cdh::hadoop'],
    }
    # Set up a job to create browser reports on hive db.
    reportupdater::job { 'browser':
        repository  => 'reportupdater-queries',
    }
}


# (stat1001)
class role::statistics::web inherits role::statistics {
    system::role { 'role::statistics::web':
        description => 'Statistics private data host and general compute node'
    }

    # include stuff common to statistics webserver nodes.
    include statistics::web

    # # include statistics web sites
    include statistics::sites::datasets
    include statistics::sites::metrics
    include statistics::sites::stats
    # analytics.wikimedia.org will eventually supercede
    # datasets and stats.
    include statistics::sites::analytics

    ferm::service {'statistics-web':
        proto => 'tcp',
        port  => '80',
    }

}


# setup rsync to copy home dirs for server upgrade
class role::statistics::migration {

    $sourceip='10.64.21.101'

    ferm::service { 'stat-migration-rsync':
        proto  => 'tcp',
        port   => '873',
        srange => "${sourceip}/32",
    }

    include rsync::server

    file { [ '/srv/stat1001', '/srv/stat1001/home',
        '/srv/stat1001/var', '/srv/stat1001/var/www',
        '/srv/stat1001/srv',
        ]:
        ensure => 'directory',
    }

    rsync::server::module { 'home':
        path        => '/srv/stat1001/home',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

    rsync::server::module { 'varwww':
        path        => '/srv/stat1001/var/www',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

    rsync::server::module { 'srv':
        path        => '/srv/stat1001/srv',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }
}
