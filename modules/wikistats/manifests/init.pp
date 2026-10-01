# SPDX-License-Identifier: Apache-2.0
# wikistats - a MediaWiki statistics site
#
# https://wikistats.wmcloud.org
#
# This sets up a site with statistics about
# as many public MediaWiki installs as possible.
#
# It runs on an instance in the Cloud VPS project 'wikistats'.
#
# You can control this instance via https://horizon.wikimedia.org
# if you are a member or admin of the project.
#
# It will likely stay a Cloud VPS project forever although
# results from it are used for some statistic tables
# inside Wikipedia and other WMF wikis.
#
# If it goes down it would be missed but it will not cause
# any issues for production wikis. Just some outdated tables.
#
# The matching software is in another repo:
# https://gitlab.wikimedia.org/cloudvps-repos/wikistats
#
# It is not deployed as a deb package. Puppet git clones it
# to /srv/wikistats and the deploy-wikistats script copies
# the files into place.
#
# This started out as an external project to create
# wiki syntax tables for pages like "List of largest wikis"
# on meta and several similar ones for other projects
#
# Not to be confused with stats.wikimedia.org and wikistats2
# run by the WMF Analytics team.
#
# To report bugs use https://phabricator.wikimedia.org and
# tag a ticket with 'VPS-project-Wikistats'.
#
class wikistats (
    Wmflib::Ensure $jobs_ensure,
){

    $php_version = wmflib::debian_php_version()

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

    # directory used by deploy-script to store backups
    file { '/usr/lib/wikistats/backup':
        ensure  => directory,
        owner   => 'wikistatsuser',
        group   => 'wikistatsuser',
        require => User['wikistatsuser'],
    }

    file { '/usr/local/bin/wikistats':
        ensure => directory,
    }

    # deployment script that copies files in place after puppet git clones to /srv/
    file { '/usr/local/bin/wikistats/deploy-wikistats':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/wikistats/deploy-wikistats.sh',
    }

    git::clone { 'repos/cloud/wikistats':
        ensure    => latest,
        directory => '/srv/wikistats',
        branch    => 'master',
        owner     => 'wikistatsuser',
        group     => 'wikistatsuser',
        source    => 'gitlab',
    }

    $db_pass = stdlib::fqdn_rand_string(23, 'Random9Fn0rd8Seed')

    # install a db on localhost
    class { 'wikistats::db':
        db_pass     => $db_pass,
        php_version => $php_version,
    }

    # location to dump as XML files
    file { '/var/www/wikistats/xml':
        ensure => directory,
        owner  => 'wikistatsuser',
        group  => 'wikistatsuser',
        mode   => '0644',
    }

    # add /usr/local/bin/wikistats/ to PATH for all users
    file { '/etc/profile.d/wikistats_path.sh':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/wikistats/wikistats_path.sh',
    }

    # symlink into PATH to make it work with sudo without editing secure_path
    file { '/usr/local/bin/deploy-wikistats':
        ensure => 'link',
        target => '/usr/local/bin/wikistats/deploy-wikistats',
    }

    class { 'wikistats::updates':
        db_pass     => $db_pass,
        ensure      => $jobs_ensure,
        php_version => $php_version,
    }
}
