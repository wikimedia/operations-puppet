#This class sets needed packages for various statistics needs
class statistics::packages {
    package { [
        'mc',
        'zip',
        'p7zip',
        'p7zip-full',
        'subversion',
        'mercurial',
        'nodejs',
        'tofrodos',
        'git-review',
        'imagemagick',
    ]:
        ensure => 'latest',
    }

    # include mysql module base class to install mysql client
    class { '::mysql': }

# Packages needed for various python stuffs
# on statistics servers.
    package { [
        'python-geoip',
        'libapache2-mod-python',
        'python-django',
        'python-mysqldb',
        'python-yaml',
        'python-dateutil',
        'python-numpy',
        'python-scipy',
    ]:
        ensure => 'installed',
    }

# Installs java.
    if !defined(Package['openjdk-7-jdk']) {
        package { 'openjdk-7-jdk':
            ensure => 'installed',
        }
    }

# RT-2163 - plotting packages
    package { [
            'ploticus',
            'libploticus0',
            'r-base',
            'r-cran-rmysql',
            'libcairo2',
            'libcairo2-dev',
            'libxt-dev'
        ]:
        ensure => 'installed',
    }
    package { [
            'python-dev', # RT 6561
            'python3-dev', # RT 6561
            ]:
            ensure => 'installed',
    }
}


