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
    $homedir = '/var/lib/reprepro'
    $incomingdir = "${basedir}/incoming"

    class { '::reprepro':
        basedir         => $basedir,
        homedir         => $homedir,
        options         => ["outdir ${outdir}"],
        gpg_pubring     => 'puppet:///modules/releases/pubring.gpg',
        # lint:ignore:puppet_url_without_modules
        gpg_secring     => 'puppet:///private/releases/secring.gpg',
        # lint:endignore
        incomingdir     => $incomingdir,
        authorized_keys => ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIRN3017QJUoewK7PIKwMo2ojSl4Mu/YxDZC4NsryXmi4kKlCTN0DTeyVSlnDei56EngwYP1crshCCDZAzFECRMV5Hr3NmS/J+ICR0z6GQztd7bQEORot38wxOkOCXBtmqMgztAqyYv6SH3Qfn9qmjrw6/yW0lLqg6cejmYXF61YEYrXyZJm+hjOD1oaYsCdjkuE+3Ob+8t6KvTcvjxarr99RRcuKp67j+7g/HRzxDKGi8/Z8/wFIBu50W/6idhjyPzYIunU5ThFmcpHUdry4jTB1/whuec70wsgcdC6EKPVVp00BfSwBaRJKlVCMWvI1VilLpMC2WtLZXpSQ5iTJ1'],
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
        group   => 'reprepro',
        mode    => '0755',
        require => Class['::reprepro'],
    }

    class { '::reprepro::distribution':
        basedir  => $basedir,
        settings => {
            'precise' => {
                'Origin'        => 'MediaWiki',
                'Label'         => 'MediaWiki',
                'Suite'         => 'precise-mediawiki',
                'Codename'      => 'precise-mediawiki',
                'AlsoAcceptFor' => 'precise',
                'Version'       => '12.04',
                'Architectures' => 'source amd64 i386',
                'Components'    => 'main',
                'Description'   => 'MediaWiki packages for Ubuntu Precise Pangolin',
                'SignWith'      => 'default',
                'Log'           => "precise-mediawiki\n  log",
            },
            'trusty'  => {
                'Origin'        => 'MediaWiki',
                'Label'         => 'MediaWiki',
                'Suite'         => 'trusty-mediawiki',
                'Codename'      => 'trusty-mediawiki',
                'AlsoAcceptFor' => 'trusty',
                'Version'       => '14.04',
                'Architectures' => 'source amd64 i386',
                'Components'    => 'main',
                'Description'   => 'MediaWiki packages for Ubuntu Trusty Tahr',
                'SignWith'      => 'default',
                'Log'           => "trusty-mediawiki\n  log",
            }
        }
    }
}

class releases::reprepro::upload (
    # lint:ignore:puppet_url_without_modules
    $private_key  = 'puppet:///private/releases/id_rsa.upload',
    # lint:endignore
    $user         = 'releases',
    $group        = 'releases',
    $sudo_user    = '%wikidev',
    $homedir      = '/var/lib/releases',
    $upload_host  = 'caesium.eqiad.wmnet',
) {
    group { 'releases':
        ensure => present,
        name   => $group,
    }

    user { 'releases':
        ensure     => present,
        name       => $user,
        home       => $homedir,
        shell      => '/bin/false',
        comment    => 'Releases user',
        gid        => $group,
        managehome => true,
        require    => Group['releases'],
    }

    file { "${homedir}/.ssh":
        ensure  => directory,
        owner   => $user,
        group   => $group,
        mode    => '0700',
        require => User['releases'],
    }

    file { "${homedir}/.ssh/id_rsa.${upload_host}":
        ensure  => file,
        owner   => $user,
        group   => $group,
        mode    => '0600',
        require => User['releases'],
        source  => $private_key,
    }

    file { "${homedir}/.ssh/config":
        ensure  => file,
        owner   => $user,
        group   => $group,
        mode    => '0600',
        require => User['releases'],
        content => template('releases/ssh_config.erb'),
    }

    file { "${homedir}/.dput.cf":
        ensure  => file,
        owner   => $user,
        group   => $group,
        mode    => '0600',
        require => User['releases'],
        content => template('releases/dput.erb'),
    }

    file { '/usr/local/bin/deb-upload':
        ensure  => file,
        owner   => $user,
        group   => $group,
        mode    => '0555',
        require => User['releases'],
        source  => 'puppet:///modules/releases/deb-upload',
    }

    package { 'dput':
        before => File['/usr/local/bin/deb-upload'],
    }

    sudo::user { 'releases_dput':
        user       => $sudo_user,
        privileges => ["ALL = (${user}) NOPASSWD: /usr/bin/dput"],
    }
}
