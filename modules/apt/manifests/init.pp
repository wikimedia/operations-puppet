class apt {
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

    apt::repository { 'wikimedia':
        uri         => 'http://apt.wikimedia.org/wikimedia',
        dist        => "${::lsbdistcodename}-wikimedia",
        components  => 'main universe non-free',
        comment_old => true,
    }

    # prefer Wikimedia APT repository packages in all cases
    apt::pin { 'wikimedia':
        package  => '*',
        pin      => 'release o=Wikimedia',
        priority => 1001,
    }

    $enable_proxy = $::site ? {
        pmtpa   => present,
        eqiad   => present,
        ulsfo   => present,
        esams   => present,
        default => absent
    }
    # This will munge /etc/apt/apt.conf that get's created during installation
    # process (either labs vmbuilder or d-i). Given the ones below exist, it is
    # no longer needed after the installation is over
    file { '/etc/apt/apt.conf':
        ensure  => absent,
        require => [
                Apt::Conf['wikimedia-proxy'],
                Apt::Conf['security-ubuntu-proxy'],
                Apt::Conf['ubuntu-cloud-archive-proxy'],
                Apt::Conf['old-releases-proxy'],
                ]
    }
    apt::conf {
        'wikimedia-proxy':
            ensure   => absent,
            priority => '80',
            key      => 'Acquire::http::Proxy',
            value    => 'http://carbon.wikimedia.org:8080';
        'security-ubuntu-proxy':
            ensure   => $enable_proxy,
            priority => '80',
            key      => 'Acquire::http::Proxy::security.ubuntu.com',
            value    => 'http://carbon.wikimedia.org:8080';
        'ubuntu-cloud-archive-proxy':
            ensure   => $enable_proxy,
            priority => '80',
            key      => 'Acquire::http::Proxy::ubuntu-cloud.archive.canonical.com',
            value    => 'http://carbon.wikimedia.org:8080';
        'old-releases-proxy':
            ensure   => $enable_proxy,
            priority => '80',
            key      => 'Acquire::http::Proxy::old-releases.ubuntu.com',
            value    => 'http://carbon.wikimedia.org:8080';
    }

    # apt-get should not install recommended packages
    apt::conf { 'no-recommends':
        ensure   => 'present',
        priority => '90',
        key      => 'APT::Install-Recommends',
        value    => '0',
    }
}
