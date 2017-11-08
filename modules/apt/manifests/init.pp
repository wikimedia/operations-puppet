class apt(
    $use_proxy = true,
    $use_experimental = hiera('apt::use_experimental', false),
) {
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

    file { '/etc/apt/sources.list.d':
        ensure => directory,
        owner => 'root',
        group => 'root',
        mode => '0755',
        recurse => true,
        purge => true,
    }

    # This will munge /etc/apt/apt.conf that get's created during installation
    # process (either labs vmbuilder or d-i). Given the ones below exist, it is
    # no longer needed after the installation is over
    file { '/etc/apt/apt.conf':
        ensure => absent,
        notify => Exec['apt-get update'],
    }

    if $use_proxy {
        $http_proxy = "http://webproxy.${::site}.wmnet:8080"

        if $::operatingsystem == 'Debian' {
            apt::conf { 'security-debian-proxy':
                ensure   => present,
                priority => '80',
                key      => 'Acquire::http::Proxy::security.debian.org',
                value    => $http_proxy,
            }
            apt::conf { 'security-cdn-debian-proxy':
                ensure   => present,
                priority => '80',
                key      => 'Acquire::http::Proxy::security-cdn.debian.org',
                value    => $http_proxy,
            }
        } elsif $::operatingsystem == 'Ubuntu' {
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
            fail("Unknown operating system '${::operatingsystem}'.")
        }
    }

    if os_version('ubuntu trusty') {
        $components = 'main universe thirdparty'
    } elsif os_version('debian jessie') {
        $components = 'main backports thirdparty'
    } else {
        if $facts['is_virtual'] == false {
            # RAID tools only needed on bare metal servers
            $components = 'main thirdparty/hwraid'
        } else {
            $components = 'main'
        }
    }

    apt::repository { 'wikimedia':
        uri         => 'http://apt.wikimedia.org/wikimedia',
        dist        => "${::lsbdistcodename}-wikimedia",
        components  => $components,
        comment_old => true,
    }

    # enable backports for Debian systems
    if $::operatingsystem == 'Debian' {
        apt::repository { 'debian-backports':
            uri         => 'http://mirrors.wikimedia.org/debian/',
            dist        => "${::lsbdistcodename}-backports",
            components  => 'main contrib non-free',
            comment_old => true,
        }
    }

    $use_experimental_ensure = $use_experimental ? {
        true    => present,
        false   => absent,
        default => absent,
    }

    if $::operatingsystem == 'Debian' {
        apt::repository { 'wikimedia-experimental':
            ensure     => $use_experimental_ensure,
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'experimental',
        }
    }

    # apt-get should not install recommended packages
    apt::conf { 'no-recommends':
        ensure   => 'present',
        priority => '90',
        key      => 'APT::Install-Recommends',
        value    => '0',
    }
}
