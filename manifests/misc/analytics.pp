# Class: misc::analytics::packages
#
# Installs needed packages for analytics tools.
# Currently these are needed by the pipeline data 
# transformation tool.  This is a work in progress.
class misc::analytics::packages
{
  package { 'python-mysqldb':
    ensure   => 'installed',
  }

  package { 'pywurfl':
    provider => 'pip',
    ensure => 'installed',
  }

  package { 'python-geoip':
    ensure => 'installed',
  }
}

