# === Class contint::packages::python
#
# This class sets up packages needed for general python testing
#
class contint::packages::python {
    require_package( # Let us compile python modules:
        'build-essential',
        'python-dev',
        'python-pip',  # Needed to install pip from pypi
    )

    # Bring in fresh pip. The Jessie package does not provide wheels cache
    # https://pip.pypa.io/en/latest/news.html
    package { 'pip':
        ensure   => '8.1.2',
        provider => 'pip',
        require  => Package['python-pip'],  # eggs and chicken
    }

    # Bring tox/virtualenv... from pip  T46443
    package { 'tox':
        ensure   => '2.5.0',
        provider => 'pip',
        require  => Package['pip'],  # Fresh pip version
    }

    # 'pip install pip' deletes /usr/bin/pip :(
    file { '/usr/bin/pip':
        ensure  => link,
        target  => '/usr/local/bin/pip',
        owner   => 'root',
        group   => 'root',
        require => Package['pip'],
    }
    package { 'setuptools':
        ensure   => present,
        provider => 'pip',
        require  => Package['python-pip'],
    }

    # Python 3
    require_package(
        'python3',
        'python3-dev',
    )
}
