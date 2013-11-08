# Package dependencies for the wikibugs script
class irc::wikibugs::packages {
  package { 'libemail-mime-perl':
    ensure => present;
  }
}

