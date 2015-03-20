# == Class: mediawiki::scap
#
# 'scap' is the command-line tool deployment tool we use to push
# MediaWiki code and configuration changes. This module ensures that
# scap is installed, that the shell environment is configured for
# MediaWiki, and that the MediaWiki deployment directory exists and
# contains a copy of MediaWiki.

# === Parameters:
# [*config*]
#   optional hash - creates ini at /etc/scap.cfg to override scap config
#
class mediawiki::scap (
    $config = undef,
) {
    include ::mediawiki::users

    $mediawiki_deployment_dir = '/srv/mediawiki'
    $mediawiki_staging_dir    = '/srv/mediawiki-staging'
    $scap_bin_dir             = '/srv/deployment/scap/scap/bin'
    $mediawiki_web_user       = $::mediawiki::users::web

    # 'scap' is the command-line tool we use to push MediaWiki changes
    # to the webapp servers. The name stands for 'sync-common-all-php'.

    package { 'scap':
        ensure   => latest,
        provider => 'trebuchet',
    }


    # /srv/mediawiki is the root path of the MediaWiki deployment tree.

    file { $mediawiki_deployment_dir:
        ensure => directory,
        owner  => 'mwdeploy',
        group  => 'mwdeploy',
        mode   => '0775',
    }


    # /etc/profile.d/mediawiki.sh declares the MEDIAWIKI_DEPLOYMENT_DIR
    # and MEDIAWIKI_STAGING_DIR environment variables and adds scap to
    # $PATH for users in the wikidev group.

    file { '/etc/profile.d/mediawiki.sh':
        content => template('mediawiki/mediawiki.sh.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }


    # If this is a new install, populate /srv/mediawiki by retrieving
    # the current MediaWiki deployment tree from the deployment server.

    if $config {
        $ini_header = "${::hostname}.${::domain}"
        $ini_config = php_ini($config)
        file { '/etc/scap.cfg':
            content => template('mediawiki/scap.cfg.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
        }
    }

    exec { 'fetch_mediawiki':
        command => "${scap_bin_dir}/sync-common",
        creates => "${mediawiki_deployment_dir}/docroot",
        require => [ File[$mediawiki_deployment_dir], Package['scap'] ],
        timeout => 30 * 60,  # 30 minutes
    }
}
