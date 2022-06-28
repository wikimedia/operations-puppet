class apt(
    Boolean $purge_sources           = false,
    Boolean $purge_preferences       = false,
    Boolean $use_proxy               = true,
    Boolean $manage_apt_source       = false,
    Boolean $install_audit_installed = false,
    String  $mirror                  = 'mirrors.wikimedia.org',
    Boolean $use_private_repo        = false,
) {
    $components =  $facts['is_virtual'] ? {
        true    => 'main',
        default => 'main thirdparty/hwraid',
    }

    exec { 'apt-get update':
        path        => '/usr/bin',
        timeout     => 240,
        returns     => [ 0, 100 ],
        refreshonly => true,
    }

    # Directory to hold the repository signing keys
    file { '/var/lib/apt/keys':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0700',
        recurse => true,
        purge   => true,
    }

    # prefer Wikimedia APT repository packages in all cases
    apt::pin { 'wikimedia':
        package  => '*',
        pin      => 'release o=Wikimedia',
        priority => 1001,
    }

    if $manage_apt_source {

        # Starting with bullseye, the security suite moved from
        # foo/updates to foo-security (since the former was confusingly
        # similar to foo-updates (what was called volatile.debian.org
        # in the past)
        if debian::codename::ge('bullseye') {
            $apt_template    = 'apt/base-apt-conf-new.erb'
        } else {
            $apt_template    = 'apt/base-apt-conf.erb'
        }

        file { '/etc/apt/sources.list':
            ensure  => file,
            mode    => '0555',
            owner   => 'root',
            group   => 'root',
            content => template($apt_template),
            require => Apt::Repository['wikimedia'],
        }
    }

    file { '/etc/apt/sources.list.d':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => $purge_sources,
        purge   => $purge_sources,
    }
    file { '/etc/apt/preferences.d':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => $purge_preferences,
        purge   => $purge_preferences,
    }

    if $use_proxy {
        $http_proxy = "http://webproxy.${::site}.wmnet:8080"
        apt::conf { 'security-debian-proxy':
            ensure   => present,
            priority => '80',
            key      => 'Acquire::http::Proxy::security.debian.org',
            value    => $http_proxy,
            before   => File['/etc/apt/apt.conf'],
        }
        apt::conf { 'security-cdn-debian-proxy':
            ensure   => present,
            priority => '80',
            key      => 'Acquire::http::Proxy::security-cdn.debian.org',
            value    => $http_proxy,
            before   => File['/etc/apt/apt.conf']
        }
        apt::conf { 'deb-debian-org':
            ensure   => present,
            priority => '80',
            key      => 'Acquire::http::Proxy::deb.debian.org',
            value    => $http_proxy,
            before   => File['/etc/apt/apt.conf']
        }
    }

    apt::repository { 'wikimedia':
        uri         => 'http://apt.wikimedia.org/wikimedia',
        dist        => "${::lsbdistcodename}-wikimedia",
        components  => $components,
        comment_old => true,
    }

    if debian::codename::ge('bullseye') and $use_private_repo and !$facts['is_virtual']{
        $ensure_private_repo = present
    } else {
        $ensure_private_repo = absent
    }

    apt::repository { 'wikimedia-private':
        ensure     => $ensure_private_repo,
        uri        => 'http://apt.wikimedia.org:8080',
        dist       => "${::lsbdistcodename}-wikimedia-private",
        components => 'thirdparty/hwraid',
    }

    if debian::codename::ge('buster'){
        apt::repository { 'debian-backports':
            uri         => 'http://mirrors.wikimedia.org/debian/',
            dist        => "${::lsbdistcodename}-backports",
            components  => 'main contrib non-free',
            comment_old => true,
        }
    }

    apt::repository { 'debian-debug':
        uri        => 'http://deb.debian.org/debian-debug',
        dist       => "${::lsbdistcodename}-debug",
        components => 'main contrib non-free',
        source     => false,
    }

    apt::conf { 'InstallRecommends':
        ensure   => 'present',
        priority => '00',
        key      => 'APT::Install-Recommends',
        value    => false,
        before   => File['/etc/apt/apt.conf'],
    }

    if debian::codename::ge('buster') {
        apt::conf { 'apt-harden':
            ensure   => 'present',
            priority => '30',
            key      => 'APT::Sandbox::Seccomp',
            value    => true,
            before   => File['/etc/apt/apt.conf'],
        }
    }

    # This will munge /etc/apt/apt.conf that get's created during installation
    # process (either labs vmbuilder or d-i). Given the ones below exist, it is
    # no longer needed after the installation is over
    file { '/etc/apt/apt.conf':
        ensure => absent,
        notify => Exec['apt-get update'],
    }
    if $install_audit_installed {
        file {'/usr/local/sbin/apt-audit-installed':
            ensure => file,
            mode   => '0555',
            source => 'puppet:///modules/apt/apt_audit_installed.py',
        }
        file {'/usr/local/share/apt':
            ensure => directory,
        }

        if debian::codename::ge('stretch') {
            file {'/usr/local/share/apt/base_packages.txt':
                ensure => file,
                mode   => '0555',
                source => "puppet:///modules/apt/base_packages.${facts['os']['distro']['codename']}",
            }
        }
    }
}
