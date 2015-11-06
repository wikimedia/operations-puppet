# === Class contint::packages::python
#
# This class sets up packages needed for general python testing
#
class contint::packages::python {
    require_package( # Let us compile python modules:
        'build-essential',
        'python-dev',
        'python-pip',  # Needed to install pip from pypi
        'libmysqlclient-dev',  # For python SQLAlchemy
        'libxml2-dev',   # For python lxml
        'libxslt1-dev',  # For python lxml
        'libffi-dev', # For python requests[security]
        'libssl-dev', # python cryptography
        'libcurl4-gnutls-dev', # For pycurl
    )

    if os_version('debian jessie') {
        # Debian only has: Suggests: libgnutls28-dev
        # Whereas on Ubuntu libgnutls-dev is a dependency
        require_package('libgnutls28-dev')
    }

    # Bring in fresh pip. The Trusty package does not provide wheels cache
    # https://pip.pypa.io/en/latest/news.html
    package { 'pip':
        ensure   => '7.1.0',
        provider => 'pip',
        require  => Package['python-pip'],  # eggs and chicken
    }

    # Bring tox/virtualenv... from pip  T46443
    package { 'tox':
        ensure   => '1.9.2',
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
        'python3-tk',  # For pywikibot/core running tox-doc-trusty
    )
}
