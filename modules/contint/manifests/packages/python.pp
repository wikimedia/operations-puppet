# === Class contint::packages::python
#
# This class sets up packages needed for general python testing
#
class contint::packages::python {
    require_package( # Let us compile python modules:
        'build-essential',
        'python-dev',
        'python-pip',
        'libmysqlclient-dev',  # For python SQLAlchemy
        'libxml2-dev',   # For python lxml
        'libxslt1-dev',  # For python lxml
        'libffi-dev', # For python requests[security]
    )
    # Bring tox/virtualenv... from pip  T46443
    package { 'tox':
        ensure   => '1.9.2',
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
