# (stat1003 / stat1006)
class role::statistics::cruncher inherits role::statistics::base {
    system::role { 'statistics::cruncher':
        description => 'Statistics general compute node (non private data)'
    }

    include ::standard
    include ::base::firewall
    include ::profile::backup::host
    backup::set { 'home' : }

    statistics::mysql_credentials { 'research':
        group => 'researchers',
    }

    # include stuff common to statistics compute nodes
    include ::statistics::compute

    # rsync logs from logging hosts
    include ::statistics::rsync::eventlogging

    include ::profile::reportupdater::jobs::mysql

    # geowiki: bringing data from production slave db to research db
    include geowiki::job::data
    # geowiki: generate limn files from research db and push them
    include geowiki::job::limn
    # geowiki: monitors the geowiki files of http://gp.wmflabs.org/
    include geowiki::job::monitoring

}
