define labs_debrepo::repo ($dir = $title, $handle = 'labsdebrepo') {
    # Manage $dir: Make sure it's a directory and turn it into a deb
    # repository.
    file { $dir:
        ensure => directory,
    }

    # Run "dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz".
    # dpkg-scanpackages is in dpkg-dev.
    ensure_packages(['dpkg-dev'])
    exec { "Turn ${dir} into deb repo":
        cwd     => $dir,
        command => '/usr/bin/dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz',
        # Only run if Packages.gz is *not* the newest file in the
        # directory or doesn't exist at all.
        onlyif  => '/usr/bin/test ! -e Packages.gz -o $(find . -newer Packages.gz | wc -l) -gt 0',
        require => [Package['dpkg-dev'], File[$dir]],
    }

    # Add the directory-turned-repository to sources.list.
    file { "/etc/apt/sources.list.d/${handle}.list":
        content => inline_template("deb [trusted=yes] file://<%= @dir %>/ /\n"),
        require => Exec["Turn ${dir} into deb repo"],
    }
    file { "/etc/apt/preferences.d/${handle}.pref":
        content => 'Explanation: Prefer local repo above others
Package: *
Pin: origin
Pin-Priority: 1500
'
    }
}

