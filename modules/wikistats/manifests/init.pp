# wikistats - mediawiki statistics site
#
# this sets up a site with statistics about
# as many public mediawiki installs as possible
# not just WMF wikis, but any mediawiki
#
# this is https://wikistats.wmflabs.org and will likely
# forever stay a labs project but be semi production
# results from it are used for WMF projects since
#
# it started out as an external project to create
# wiki syntax tables for pages like "List of largest wikis"
# on meta and several similar ones for other projects
# not to be confused with stats.wm by analytics
class wikistats (
    Stdlib::Fqdn $wikistats_host,
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
        owner  => 'wikistatsuser',
        group  => 'wikistatsuser',
    }

    # directory used by deploy-script to store backups
    file { '/usr/lib/wikistats/backup':
        ensure  => 'directory',
        owner   => 'wikistatsuser',
        group   => 'wikistatsuser',
        require => User['wikistatsuser'],
    }

    file { '/usr/local/bin/wikistats':
        ensure => 'directory',
    }

    # deployment script that copies files in place after puppet git clones to /srv/
    file { '/usr/local/bin/wikistats/deploy-wikistats':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/wikistats/deploy-wikistats.sh',
    }

    # FIXME rename repo, it was a deb in the past
    # but not anymore and also not operations
    git::clone { 'operations/debs/wikistats':
        ensure    => 'latest',
        directory => '/srv/wikistats',
        branch    => 'master',
        owner     => 'wikistatsuser',
        group     => 'wikistatsuser',
    }

    # webserver setup for wikistats
    class { 'wikistats::web':
        wikistats_host => $wikistats_host,
    }

    $db_pass = fqdn_rand_string(23, 'Random9Fn0rd8Seed')

    # install a db on localhost
    class { 'wikistats::db':
        db_pass => $db_pass,
    }

    # scripts and crons to update data and dump XML files
    file { '/var/www/wikistats/xml':
        ensure => directory,
        owner  => 'wikistatsuser',
        group  => 'wikistatsuser',
        mode   => '0644',
    }

    class { 'wikistats::updates':
        db_pass => $db_pass,
    }
}

