# == Class: wikidata::builder

class wikidata::builder {

package { [
    'nodejs',
    'npm',
    'php5',
    'php5-cli',
    'git'
]:
    ensure => 'present',
}

exec { 'grunt-cli_install':
    user => 'root',
    command => '/usr/bin/npm install -g grunt-cli',
    require => Package['nodejs', 'npm'],
}

group { 'wdbuilder':
    ensure => present,
}

user { 'wdbuilder':
    ensure => 'present',
    home => '/home/wdbuilder',
    shell => '/bin/bash',
    managehome => true,
}

git::clone { 'wikidatabuilder':
    ensure => 'latest',
    directory => '/home/wdbuilder/buildscript',
    origin => 'https://github.com/wmde/WikidataBuilder.git',
    owner => 'wdbuilder',
    group => 'wdbuilder',
    require => File['/home/wdbuilder'],
}

git::clone { 'wikidata':
    ensure => 'latest',
    directory => '/home/wdbuilder/wikidata',
    # TODO use a different repo once deploying!
    origin => 'https://github.com/addshore/WikidataBuild.git',
    owner => 'wdbuilder',
    group => 'wdbuilder',
    require => File['/home/wdbuilder'],
}

git::userconfig{ 'gitconf for jenkins user':
    homedir => '/home/wdbuilder',
    settings => {
        'user' => {
            'name' => 'WikidataBuilder',
            'email' => 'wikidata@wikimedia.de',
        },
    },
    require => File['/home/wdbuilder'],
}

exec { 'npm_install':
    user => 'root',
    cwd => '/home/wdbuilder/buildscript',
    command => '/usr/bin/npm install',
    require => [
        Package['npm'],
        Git::Clone['wikidatabuilder']
    ],
}

file { '/home/wdbuilder/builder_cron.sh':
    ensure => file,
    mode => '0755',
    owner => 'wdbuilder',
    group => 'wdbuilder',
    source => 'puppet:///modules/wikidata/builder_cron.sh',
    require => [
        Exec['npm_install'],
        Git::Clone['wikidata']
    ],
}

# TODO uncomment when ready
# cron { 'builder_cron':
#     ensure => present,
#     # TODO commit the build to another repo
#     command => '/home/wdbuilder/builder_cron.sh',
#     user => 'wdbuilder',
#     hour => '*/1',
#     minute => [ 0, 30 ],
#     require => [ File['/home/wdbuilder/builder_cron.sh'] ],
# }

}