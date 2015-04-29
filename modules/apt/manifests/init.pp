class apt {
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

    package { 'apt-show-versions':
        ensure => installed,
    }

    package { 'python-apt':
        ensure => installed,
    }

    file { '/usr/local/bin/apt2xml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/apt/apt2xml.py',
        require => Package['python-apt'],
    }

    # prefer Wikimedia APT repository packages in all cases
    apt::pin { 'wikimedia':
        package  => '*',
        pin      => 'release o=Wikimedia',
        priority => 1001,
    }
    # TODO: Remove after applied everywhere.
    file { '/etc/apt/preferences.d/wikimedia':
        ensure  => absent,
        require => Apt::Pin['wikimedia'],
        notify  => Exec['apt-get update'],
    }

    $http_proxy = "http://webproxy.${::site}.wmnet:8080"

    # This will munge /etc/apt/apt.conf that get's created during installation
    # process (either labs vmbuilder or d-i). Given the ones below exist, it is
    # no longer needed after the installation is over
    file { '/etc/apt/apt.conf':
        ensure  => absent,
        notify  => Exec['apt-get update'],
    }

    apt::conf { 'wikimedia-proxy':
        ensure   => absent,
        priority => '80',
        key      => 'Acquire::http::Proxy',
        value    => $http_proxy,
    }

    if downcase($::lsbdistid) == 'debian' {
        $components = 'main backports thirdparty'

        apt::conf { 'security-debian-proxy':
            ensure   => present,
            priority => '80',
            key      => 'Acquire::http::Proxy::security.debian.org',
            value    => $http_proxy,
        }
    } elsif downcase($::lsbdistid) == 'ubuntu' {
        $components = 'main universe thirdparty'

        apt::conf { 'security-ubuntu-proxy':
            ensure   => present,
            priority => '80',
            key      => 'Acquire::http::Proxy::security.ubuntu.com',
            value    => $http_proxy,
        }

        apt::conf { 'ubuntu-cloud-archive-proxy':
            ensure   => present,
            priority => '80',
            key      => 'Acquire::http::Proxy::ubuntu-cloud.archive.canonical.com',
            value    => $http_proxy,
        }

        apt::conf { 'old-releases-proxy':
            ensure   => present,
            priority => '80',
            key      => 'Acquire::http::Proxy::old-releases.ubuntu.com',
            value    => $http_proxy,
        }
    } else {
        fail("Unknown operating system '$::lsbdistid'.")
    }

    apt::repository { 'wikimedia':
        uri         => 'http://apt.wikimedia.org/wikimedia',
        dist        => "${::lsbdistcodename}-wikimedia",
        components  => $components,
        comment_old => true,
    }

    # apt-get should not install recommended packages
    apt::conf { 'no-recommends':
        ensure   => 'present',
        priority => '90',
        key      => 'APT::Install-Recommends',
        value    => '0',
    }
}
