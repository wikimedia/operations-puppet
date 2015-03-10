# licence AGPL version 3 or later
class wikidatabuilder {

    requires_realm('labs')

    package { [
            'nodejs',
            'npm',
            'php5',
            'php5-cli',
            'git'
        ]: ensure => 'present',
    }

    exec { 'npm_registry_http':
        user => 'root',
        command => '/usr/bin/npm config set registry="http://registry.npmjs.org/"',
        require => Package['nodejs', 'npm'],
    }

    # sadly npm has no way of telling it the name of the nodejs binary and upstream refuses to fix that https://github.com/joyent/node/issues/3911
    $fixnodejs = shellquote('sed', '-i', 's|^#!/usr/bin/env node$|#!/usr/bin/env nodejs|')
    exec { 'grunt-cli_install':
        user => 'root',
        command => "/usr/bin/npm install -g grunt-cli && $fixnodejs /usr/local/lib/node_modules/grunt-cli/bin/grunt",
        require => Exec['npm_registry_http'],
    }

    group { 'wdbuilder':
        ensure => present,
    }

    user { 'wdbuilder':
        ensure => 'present',
        home => '/data/wdbuilder',
        shell => '/bin/bash',
        managehome => true,
        system => true,
    }

    git::clone { 'wdbuilder composer':
        ensure => 'latest',
        directory => '/data/wdbuilder/composer',
        origin => 'https://gerrit.wikimedia.org/r/p/integration/composer.git',
        owner => 'wdbuilder',
        group => 'wdbuilder',
        recurse_submodules => true,
    }

    exec { 'ssh-keygen':
        user => 'wdbuilder',
        command => "/usr/bin/ssh-keygen -t rsa -b 4096 -C 'wikidatabuilder on $::fqdn $::projectgroup' -f /data/wdbuilder/.ssh/id_rsa && cat /data/wdbuilder/.ssh/id_rsa.pub",
        require => User['wdbuilder'],
        creates => '/data/wdbuilder/.ssh/id_rsa',
    }

    file { '/data/wdbuilder/.ssh/known_hosts':
        ensure => file,
        mode => '0755',
        owner => 'wdbuilder',
        group => 'wdbuilder',
        source => 'puppet:///modules/wikidatabuilder/ssh-client-known_hosts',
        require => Exec['ssh-keygen'],
    }

    file { '/data/wdbuilder/.ssh/config':
        ensure => file,
        mode => '0755',
        owner => 'wdbuilder',
        group => 'wdbuilder',
        source => 'puppet:///modules/wikidatabuilder/ssh-client-config',
        require => Exec['ssh-keygen'],
    }

    file { '/data/wdbuilder/wikidata/.git/hooks/commit-msg':
        ensure => file,
        mode => '0755',
        owner => 'wdbuilder',
        group => 'wdbuilder',
        source => 'puppet:///modules/wikidatabuilder/git-hook-commit-msg-gerrit',
    }

    git::clone { 'wikidatabuilder':
        ensure => 'latest',
        directory => '/data/wdbuilder/buildscript',
        origin => 'https://github.com/wmde/WikidataBuilder.git',
        owner => 'wdbuilder',
        group => 'wdbuilder',
        require => [ File['/data/wdbuilder/.ssh/config'], File['/data/wdbuilder/.ssh/known_hosts'] ],
    }

    git::clone { 'wikidatabuildresources':
        ensure => 'latest',
        directory => '/data/wdbuilder/buildresources',
        origin => 'https://github.com/wmde/WikidataBuildResources.git',
        owner => 'wdbuilder',
        group => 'wdbuilder',
        require => [ File['/data/wdbuilder/.ssh/config'], File['/data/wdbuilder/.ssh/known_hosts'] ],
    }

    git::clone { 'wikidata':
        ensure => 'latest',
        directory => '/data/wdbuilder/wikidata',
        origin => 'ssh://wikidatabuilder@gerrit.wikimedia.org:29418/mediawiki/extensions/Wikidata',
        # origin => 'git@github.com:addshore/WikidataBuild.git',
        owner => 'wdbuilder',
        group => 'wdbuilder',
        require => File['/data/wdbuilder/.ssh/config'],
    }

    git::userconfig{ 'gitconf for wdbuilder user':
        homedir => '/data/wdbuilder',
        settings => {
            'user' => {
                'name' => 'WikidataBuilder',
                'email' => 'wikidata-services@wikimedia.de',
            },
        },
        require => User['wdbuilder'],
    }

    exec { 'npm_install':
        user => 'root',
        cwd => '/data/wdbuilder/buildresources',
        command => '/usr/bin/npm install',
        require => [
            Package['npm'],
            Git::Clone['wikidatabuilder']
        ],
    }

    file { '/data/wdbuilder/cron-build.sh':
        ensure => file,
        mode => '0755',
        owner => 'wdbuilder',
        group => 'wdbuilder',
        source => 'puppet:///modules/wikidatabuilder/cron-build.sh',
        require => [
            Exec['npm_install'],
            Git::Clone['wikidata']
        ],
    }

    cron { 'builder_cron':
        ensure => present,
        command => '/data/wdbuilder/cron-build.sh > /data/wdbuilder/cron.log 2>&1',
        user => 'wdbuilder',
        hour => '10',
        minute => '0',
        require => [ File['/data/wdbuilder/cron-build.sh'], File['/data/wdbuilder/wikidata/.git/hooks/commit-msg'] ],
    }

}
