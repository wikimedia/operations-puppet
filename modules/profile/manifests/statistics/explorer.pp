# == Class profile::statistics::explorer
#
class profile::statistics::explorer {

    include ::profile::statistics::base

    class { '::deployment::umask_wikidev': }

    # Include the MySQL research password at
    # /etc/mysql/conf.d/analytics-research-client.cnf
    # and only readable by users in the
    # analytics-privatedata-users group.
    statistics::mysql_credentials { 'analytics-research':
        group => 'analytics-privatedata-users',
    }

    # This file will render at
    # /etc/mysql/conf.d/researchers-client.cnf.
    # This is so that users in the researchers
    # group can access the research slave dbs.
    statistics::mysql_credentials { 'research':
        group => 'researchers',
    }
}