# == Class: mediawiki::scap
#
# 'scap' is the command-line tool deployment tool we use to push
# MediaWiki code and configuration changes. This module ensures that
# scap is installed, that the shell environment is configured for
# MediaWiki, and that the MediaWiki deployment directory exists and
# contains a copy of MediaWiki.
#
class mediawiki::scap (
    Boolean $is_master                            = false,
    Boolean $deployment_dir_linked_to_staging_dir = false,
) {
    include ::mediawiki::users

    # /srv/mediawiki is the root path of the MediaWiki deployment tree.
    $mediawiki_deployment_dir = '/srv/mediawiki'
    $mediawiki_staging_dir = '/srv/mediawiki-staging'
    $scap_bin_dir = '/usr/bin'
    $mediawiki_web_user = $::mediawiki::users::web

    if $is_master and $deployment_dir_linked_to_staging_dir {
        file { $mediawiki_deployment_dir:
            ensure => link,
            target => $mediawiki_staging_dir,
        }
    } else {
        file { $mediawiki_deployment_dir:
            ensure => directory,
            owner  => 'mwdeploy',
            group  => 'mwdeploy',
            mode   => '0775',
        }
    }

    # If this is a new install, populate /srv/mediawiki by retrieving
    # the current MediaWiki deployment tree from the deployment server.
    $fetch_mediawiki_command = ( $is_master and $deployment_dir_linked_to_staging_dir ) ? {
        true => '/bin/true',
        default => "${scap_bin_dir}/scap pull",
    }

    exec { 'fetch_mediawiki':
        command => $fetch_mediawiki_command,
        creates => "${mediawiki_deployment_dir}/docroot",
        require => [ File[$mediawiki_deployment_dir], Sudo::User['mwdeploy'] ],
        timeout => 30 * 60,  # 30 minutes
        user    => 'mwdeploy',
        group   => 'mwdeploy',
    }

    # /etc/profile.d/mediawiki.sh declares the MEDIAWIKI_DEPLOYMENT_DIR,
    # MEDIAWIKI_STAGING_DIR, and MEDIAWIKI_WEB_USER environment variables and
    # sets umask to 002 for users in the wikidev or l10nupdate groups.

    file { '/etc/profile.d/mediawiki.sh':
        content => template('mediawiki/mediawiki.sh.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
