# == Class: mediawiki::users
#
# Provisions system accounts for running, deploying and updating
# MediaWiki.
#
class mediawiki::users(
    String $web = 'www-data',
    Optional[Array[String]] $extra_privileges = [],

) {

    # The mwdeploy account is used by various scripts in the MediaWiki
    # deployment process to run rsync.

    group { 'mwdeploy':
        ensure => present,
        system => true,
    }

    user { 'mwdeploy':
        ensure     => present,
        shell      => '/bin/bash',
        home       => '/var/lib/mwdeploy',
        system     => true,
        managehome => true,
    }

    ssh::userkey { 'mwdeploy':
        content => secret('keyholder/mwdeploy.pub'),
    }

    # Grant mwdeploy sudo rights to run anything as itself and the apache user.
    # This allows MediaWiki deployers to deploy as mwdeploy.
    sudo::user { 'mwdeploy':
        privileges => [
            "ALL = (${web},mwdeploy) NOPASSWD: ALL",
            'ALL = (root) NOPASSWD: /usr/sbin/service apache2 start',
            'ALL = (root) NOPASSWD: /usr/sbin/apache2ctl graceful-stop',
        ]+$extra_privileges,
    }
}
