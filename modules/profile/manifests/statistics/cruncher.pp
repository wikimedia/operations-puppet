# == Class profile::statistics::cruncher
#
class profile::statistics::cruncher {

    include ::profile::statistics::base
    include ::deployment::umask_wikidev

    # This file will render at
    # /etc/mysql/conf.d/researchers-client.cnf.
    # This is so that users in the researchers
    # group can access the research slave dbs.
    statistics::mysql_credentials { 'research':
        group => 'researchers',
    }
}
