# == Class: wikidata::builder

class wikidata::builder {

package { [
    'nodejs',
    'npm',
    'php5',
    'php5-cli',
    'git'
]:
    ensure => 'present';
}

exec { 'grunt-cli_install':
    user    => 'root',
    command => '/usr/bin/npm install -g grunt-cli',
    require => [
        Package['nodejs'],
        Package['npm']
    ],
}

group { 'wdbuilder':
    ensure => present,
}

user { 'wdbuilder':
    ensure     => 'present',
    home       => '/home/wdbuilder',
    name       => 'wdbuilder',
    shell      => '/bin/bash',
    managehome => true,
}

file { '/home/wdbuilder':
    ensure  => 'directory',
    owner   => 'wdbuilder',
    group   => 'wdbuilder',
    mode    => '0700',
    require => [
        User['wdbuilder'],
        Group['wdbuilder']
    ],
}

git::clone { 'clone_wikidatabuilder':
    directory => '/home/wdbuilder/buildscript',
    origin    => 'https://github.com/wmde/WikidataBuilder.git',
    ensure    => 'latest',
    owner     => 'wdbuilder',
    group     => 'wdbuilder',
    require   => [ File['/home/wdbuilder'] ],
}

git::clone { 'clone_wikidata':
    directory => '/home/wdbuilder/wikidata',
    # TODO use a different repo once deploying!
    origin    => 'https://github.com/addshore/WikidataBuild.git',
    ensure    => 'latest',
    owner     => 'wdbuilder',
    group     => 'wdbuilder',
    require   => [ File['/home/wdbuilder'] ],
}

# TODO use the git::userconfig instead of this exec
exec { 'git_setup':
    user    => 'wdbuilder',
    cwd     => '/home/wdbuilder/wikidata',
    command => '/usr/bin/git config user.email "wikidata@wikimedia.de" && /usr/bin/git config user.name "WikidataBuilder"',
    require => [ Package['git'] ],
}

# EXAMPLE
# git::userconfig{ 'gitconf for jenkins user':
#   homedir => '/var/lib/jenkins',
#   settings => {
#     'user' => {  # '[user]'
#        'name' => 'Antoine Musso',  # 'name = Antoine Musso'
#        'email' => 'hashar@free.fr', # 'email = hashar@free.fr'
#     },  # end of [user] section
#   }
# }

exec { 'npm_install':
    user    => 'root',
    cwd     => '/home/wdbuilder/buildscript',
    command => '/usr/bin/npm install',
    require => [
        Package['npm'],
        Git::Clone['clone_wikidatabuilder']
    ],
}

file { '/home/wdbuilder/builder_cron.sh':
    ensure  => file,
    mode    => '0755',
    owner   => 'wdbuilder',
    group   => 'wdbuilder',
    source  => 'puppet:///modules/wikidata/builder_cron.sh',
    require => [
        Exec['npm_install'],
        Git::Clone['clone_wikidata']
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