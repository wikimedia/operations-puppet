# === Class contint::packages::python
#
# This class sets up packages needed for general python testing
#
class contint::packages::python {
    if os_version('debian >= stretch') {
        require_package('libmariadbclient-dev') # For python SQLAlchemy
    } else {
        require_package('libmysqlclient-dev') # For python SQLAlchemy
    }

    require_package( # Let us compile python modules:
        'build-essential',
        'python-dev',
        'python-pip',  # Needed to install pip from pypi
        'libxml2-dev',   # For python lxml
        'libxslt1-dev',  # For python lxml
        'libffi-dev', # For python requests[security]
        'libssl-dev', # python cryptography
    )

    # T117955 Debian only has: Suggests: libgnutls28-dev
    require_package('libgnutls28-dev')

    require_package('librdkafka-dev') # For confluent-kafka

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
        'python3-tk',  # For pywikibot/core running tox-doc
    )
    package { 'pypy':  # pywikibot/core T134235
        ensure => present,
    }
}
