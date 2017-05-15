# wikistats - mediawiki statistics site
#
# this sets up a site with statistics about
# as many public mediawiki installs as possible
# not just WMF wikis, but any mediawiki
#
# this is http://wikistats.wmflabs.org and will likely
# forever stay a labs project but be semi production
# results from it are used for WMF projects since
#
# it started out as an external project to create
# wiki syntax tables for pages like "List of largest wikis"
# on meta and several similar ones for other projects
# not to be confused with stats.wm by analytics
class wikistats (
    $wikistats_host,
) {

    group { 'wikistatsuser':
        ensure => present,
        name   => 'wikistatsuser',
        system => true,
    }

    user { 'wikistatsuser':
        home       => '/usr/lib/wikistats',
        groups     => 'wikistatsuser',
        managehome => true,
        system     => true,
    }

    file { '/srv/wikistats':
        ensure => 'directory',
    }

    file { '/root/wsbackup':
        ensure => 'directory',
    }

    file { '/usr/local/bin/wikistats':
        ensure => 'directory',
    }

    file { '/usr/local/bin/wikistats/deploy-wikistats':
       ensure => 'present',
       owner  => 'root',
       group  => 'root',
       mode   => '0544', 
      source  => 'puppet:///modules/wikistats/deploy-wikistats',
    }
 
    # FIXME rename repo, it was a deb in the past
    # but not anymore and also not operations
    git::clone { 'operations/debs/wikistats':
        ensure    => 'latest',
        directory => '/srv/wikistats',
        branch    => 'master',
    }

    # webserver setup for wikistats
    class { 'wikistats::web':
        wikistats_host => $wikistats_host,
    }

    # data update scripts/crons for wikistats
    class { 'wikistats::updates': }

    # install a db on localhost
    class { 'wikistats::db': }
}

