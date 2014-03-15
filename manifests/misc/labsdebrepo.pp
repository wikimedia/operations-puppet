# Puppet configs to create a local deb repo and add it to your sources.list

class misc::labsdebrepo ($dir = '/data/project/repo', $handle = 'labsdebrepo') {
    # manage /data/project/repo: make sure it's a directory and turn
    # it into a deb repo.
    file { $dir:
        ensure => directory,
    }
    file { "${dir}/Packages.gz":
        ensure => present,
    }
    # run dpkg-scanpackages . /dev/null | gzip -9c > binary/Packages.gz
    # dpkg-scanpackages is in dpkg-dev
    package { 'dpkg-dev':
        ensure => present,
    }
    exec { 'Turn ${dir} into deb repo':
        cwd     => $dir,
        command => '/usr/bin/dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz',
        # only run if Packages.gz is *not* the newest file in the directory
        onlyif  => '/usr/bin/test $(find . -newer Packages.gz | wc -l) -gt 0',
        require => [Package['dpkg-dev'], File[$dir]],
    }
    # add the dir-turned-repo to sources.list
    file { '/etc/apt/sources.list.d/${handle}.list':
        content => template('misc/labsdebrepo.list'),
        require => Exec['Turn ${dir} into deb repo'],
    }
    file { '/etc/apt/preferences.d/${handle}.pref':
        content => 'Explanation: Prefer local repo above others
Package: *
Pin: origin
Pin-Priority: 1500
'
    }
}
