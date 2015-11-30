# == Class: mediawiki::users
#
# Provisions system accounts for running, deploying and updating
# MediaWiki.
#
class mediawiki::users(
    $web = 'www-data',
    $mwdeploy_pub_key = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/81k2eXC0lM00+kg+5+p3kAHoOwAcbBjktlM7DENrrWdvkSlJasPDtHsU0+7woyGz2hHpI0SA8eBAEngl1X7uX4w1HU/VcG6np/kVMVrXPtn+sy4JtYTEVLuGzUstoc8PNxEDKvEQS7WGNLZtrgY0xWYsd7grt5tI/8qvhHd7coT6EWOcisRVnGY20r+/IWgsREZarbiW+0CSdQS0UzBbKQX/Hv+1asfZ24Qmq+yvXc2GuP+ewAm5gh0+5dUBHt69Ocq3PwCvqEypOrwpaqTGJbjvGLyaRN+YBNwoVwwl3EICYOJVDnNr/UxmzBT9RAJMHcpj6XrYiCTL1P9MUXyP54nZGOeqodSVn/L62lCwlh92D+E9qa6QFk8ikjKUr34vSI5jmQnscfaVz0k96YZP9B3J6+FDZOC8E/3SGRONrf4Fd4EAZGLQnoSdmwDHGGiHs8cjKnj4SinMabFzE3ReMV5k+Kdp999ne/vC2aryDSgc+EIXz731FmjPFmG5mdb/obGWHtU58kAbTSxPGV38uh1xvOSaSshfhYqK14G57x0ieUxV3zSZmJ5BuN5JbthgVNkAlMEATT2S6Cw+bBY7xgsE/0Wv139y0ChmatFyNv3uVbnMMTtJTBQGz+9Qb4xWTw1mxCxR5PmNmEaNI9+o/uk8M7fNd1muQfOUQPQkBQ== Mediawiki deployment key',
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
        home       => '/home/mwdeploy',
        system     => true,
        managehome => true,
    }

    ssh::userkey { 'mwdeploy':
        content => $mwdeploy_pub_key,
    }

    # Grant mwdeploy sudo rights to run anything as itself, apache and the
    # l10nupdate user. This allows MediaWiki deployers to deploy as mwdeploy.
    sudo::user { 'mwdeploy':
        privileges => [
            "ALL = (${web},mwdeploy,l10nupdate) NOPASSWD: ALL",
            'ALL = (root) NOPASSWD: /sbin/restart hhvm',
            'ALL = (root) NOPASSWD: /usr/sbin/service apache2 start',
            'ALL = (root) NOPASSWD: /sbin/start hhvm',
            'ALL = (root) NOPASSWD: /usr/sbin/apache2ctl graceful-stop',
        ]
    }

    # The pybal-check account is used by PyBal to monitor server health
    # See <https://wikitech.wikimedia.org/wiki/LVS#SSH_checking>

    group { 'pybal-check':
        ensure => present,
    }

    user { 'pybal-check':
        ensure     => present,
        gid        => 'pybal-check',
        shell      => '/bin/sh',
        home       => '/var/lib/pybal-check',
        system     => true,
        managehome => true,
    }

    ssh::userkey { 'pybal-check':
        source  => 'puppet:///modules/mediawiki/pybal_key',
    }
}
