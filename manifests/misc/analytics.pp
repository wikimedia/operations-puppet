# Class: misc::analytics::packages
#
# Installs needed packages for analytics tools.
# Currently these are needed by the pipeline data 
# transformation tool.  This is a work in progress.
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

