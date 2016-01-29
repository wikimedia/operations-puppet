# licence AGPL version 3 or later
class wikidatabuilder {

    requires_realm('labs')

    require_package(
        'nodejs',
        'npm',
        'php5',
        'php5-cli',
        'git')

    group { 'wdbuilder':
        ensure => present,
    }

    user { 'wdbuilder':
        ensure     => 'present',
        home       => '/data/wdbuilder',
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
    }

    git::clone { 'wdbuilder composer':
        ensure             => 'latest',
        directory          => '/data/wdbuilder/composer',
        origin             => 'https://gerrit.wikimedia.org/r/p/integration/composer.git',
        owner              => 'wdbuilder',
        group              => 'wdbuilder',
        recurse_submodules => true,
    }

    exec { 'ssh-keygen-/data/wdbuilder/.ssh/id_rsa':
        user    => 'wdbuilder',
        command => "/usr/bin/ssh-keygen -t rsa -b 4096 -C 'wikidatabuilder on ${::fqdn} ${::projectgroup}' -f /data/wdbuilder/.ssh/id_rsa",
        require => User['wdbuilder'],
        creates => '/data/wdbuilder/.ssh/id_rsa',
    }

    file { '/data/wdbuilder/.ssh/known_hosts':
        ensure  => file,
        mode    => '0755',
        owner   => 'wdbuilder',
        group   => 'wdbuilder',
        source  => 'puppet:///modules/wikidatabuilder/ssh-client-known_hosts',
        require => Exec['ssh-keygen-/data/wdbuilder/.ssh/id_rsa'],
    }

    file { '/data/wdbuilder/.ssh/config':
        ensure  => file,
        mode    => '0755',
        owner   => 'wdbuilder',
        group   => 'wdbuilder',
        source  => 'puppet:///modules/wikidatabuilder/ssh-client-config',
        require => Exec['ssh-keygen-/data/wdbuilder/.ssh/id_rsa'],
    }

    git::clone { 'wikidata':
        ensure    => 'latest',
        directory => '/data/wdbuilder/wikidata',
        origin    => 'ssh://wikidatabuilder@gerrit.wikimedia.org:29418/mediawiki/extensions/Wikidata',
        owner     => 'wdbuilder',
        group     => 'wdbuilder',
        require   => File['/data/wdbuilder/.ssh/config'],
    }

    exec { 'exec-/data/wdbuilder/wikidata/.git/hooks/commit-msg':
        user    => 'wdbuilder',
        command => '/usr/bin/scp -p -P 29418 wikidatabuilder@gerrit.wikimedia.org:hooks/commit-msg /data/wdbuilder/wikidata/.git/hooks/commit-msg',
        creates => '/data/wdbuilder/wikidata/.git/hooks/commit-msg',
        require => [
            Git::Clone['wikidata'],
            File['/data/wdbuilder/.ssh/config'],
        ],
    }

    file { '/data/wdbuilder/wikidata/.git/hooks/commit-msg':
        mode    => '0755',
        owner   => 'wdbuilder',
        group   => 'wdbuilder',
        require => Exec['exec-/data/wdbuilder/wikidata/.git/hooks/commit-msg'],
    }

    git::clone { 'wikidatabuildresources':
        ensure    => latest,
        directory => '/data/wdbuilder/buildresources',
        origin    => 'https://gerrit.wikimedia.org/r/wikidata/build-resources',
        owner     => 'wdbuilder',
        group     => 'wdbuilder',
        require   => [
            File['/data/wdbuilder/.ssh/config'],
            File['/data/wdbuilder/.ssh/known_hosts'],
        ],
    }

    git::userconfig{ 'gitconf for wdbuilder user':
        homedir  => '/data/wdbuilder',
        settings => {
            'user' => {
                'name'  => 'WikidataBuilder',
                'email' => 'wikidata-services@wikimedia.de',
            },
        },
        require  => User['wdbuilder'],
    }

    # sadly npm has no way of telling it the name of the nodejs binary and upstream refuses to fix that https://github.com/joyent/node/issues/3911
    $fixnodejs = shellquote('sed', '-i', 's|^#!/usr/bin/env node$|#!/usr/bin/env nodejs|')
    exec { 'npm_install-/data/wdbuilder/buildresources':
        user    => 'wdbuilder',
        cwd     => '/data/wdbuilder/buildresources',
        command => "/usr/bin/npm install && ${fixnodejs} /data/wdbuilder/buildresources/node_modules/grunt-cli/bin/grunt",
        creates => '/data/wdbuilder/buildresources/node_modules',
        require => [
            Package['npm'],
            Git::Clone['wikidatabuildresources']
        ],
    }

    file { '/data/wdbuilder/cron-build.sh':
        ensure => file,
        mode   => '0755',
        owner  => 'wdbuilder',
        group  => 'wdbuilder',
        source => 'puppet:///modules/wikidatabuilder/cron-build.sh',
    }

    cron { 'builder_cron':
        ensure  => present,
        command => '/data/wdbuilder/cron-build.sh > /data/wdbuilder/cron.log 2>&1',
        user    => 'wdbuilder',
        hour    => '10',
        minute  => '0',
        require => [
            File['/data/wdbuilder/cron-build.sh'],
            File['/data/wdbuilder/wikidata/.git/hooks/commit-msg'],
            Exec['npm_install-/data/wdbuilder/buildresources'],
            Git::Userconfig['gitconf for wdbuilder user'],
            Git::Clone['wdbuilder composer'],
        ],
    }

}
