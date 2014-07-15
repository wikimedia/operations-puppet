# == Class: releases::reprepro
#
#   Configures reprepro for releases.wikimedia.org
#
#   This configuration will keep everything reprepro-related under $basedir,
#   save for the exported files which are published under $outdir and thus
#   under the releases document root.
#
#   Packages can be uploaded into $incomingdir in the form of .changes files,
#   currently any valid gpg signature will be allowed (i.e. any key that's in
#   the public keyring).
#
#   The result will be signed by the default key present in the secret
#   keyring.

class releases::reprepro {
    $basedir = '/srv/org/wikimedia/reprepro'
    $outdir = '/srv/org/wikimedia/releases/debian'
    $incomingdir = "${basedir}/incoming"

    class { '::reprepro':
        basedir => $basedir,
        options => ["outdir ${outdir}"],
        gpg_pubring => 'puppet:///modules/releases/pubring.gpg',
        gpg_secring => 'puppet:///private/releases/secring.gpg',
        incomingdir => $incomingdir,
        uploaders => ['allow * by any key'],
    }

    file { $outdir:
        ensure  => directory,
        owner   => 'reprepro',
        group   => 'reprepro',
        mode    => '0755',
        require => Class['::reprepro'],
    }

    file { $incomingdir:
        ensure  => directory,
        owner   => 'reprepro',
        group   => 'wikidev',
        mode    => '0775',
        require => Class['::reprepro'],
    }

#    cron { 'processincoming':
#        ensure  => present,
#        command => "reprepro -Vb ${basedir} processincoming default >> ${basedir}/logs/processincoming.log 2>&1",
#        user    => 'reprepro',
#        hour    => '*',
#        minute  => '*/5',
#    }

    class { '::reprepro::distribution':
        basedir => $basedir,
        settings => {
            'precise' => {
                'Origin' => 'MediaWiki',
                'Label'  => 'MediaWiki',
                'Suite'  => 'precise-mediawiki',
                'Codename' => 'precise-mediawiki',
                'AlsoAcceptFor' => 'precise',
                'Version' => '12.04',
                'Architectures' => 'source amd64 i386',
                'Components' => 'main',
                'Description' => 'MediaWiki packages for Ubuntu Precise Pangolin',
                'SignWith' => 'default',
                'Uploaders' => 'uploaders',
                'Log' => "precise-mediawiki\n  log",
            },
            'trusty' => {
                'Origin' => 'MediaWiki',
                'Label'  => 'MediaWiki',
                'Suite'  => 'trusty-mediawiki',
                'Codename' => 'trusty-mediawiki',
                'AlsoAcceptFor' => 'trusty',
                'Version' => '14.04',
                'Architectures' => 'source amd64 i386',
                'Components' => 'main',
                'Description' => 'MediaWiki packages for Ubuntu Trusty Tahr',
                'SignWith' => 'default',
                'Uploaders' => 'uploaders',
                'Log' => "trusty-mediawiki\n  log",
            }
        }
    }
}
