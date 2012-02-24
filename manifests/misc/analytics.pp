# Class: misc::analytics::packages
#
# Installs needed packages for analytics tools.
class misc::analytics::packages
{
  include generic::mysql::client
  
  package { 'MySQL-python':
    provider => 'pip',
    ensure   => 'installed',
    requires => Class['generic::mysql::client'],
  }
  
  package { 'pywurfl':
    provider => 'pip',
    ensure => 'installed',
  }
  
  package { 'python-geoip': 
    ensure => 'installed',
  }
}

