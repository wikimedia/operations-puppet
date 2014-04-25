# Wikibugs - homegrown perl script feed with bugzilla email notification
# will write some oneliner notification in a file to be processed by
# ircecho.
#
# Documentation: http://wikitech.wikimedia.org/view/Wikibugs
# Sourcecode: svn /trunk/tools/wikibugs
#

# Package dependencies for the wikibugs script
class misc::irc::wikibugs::packages {
  package { 'libemail-mime-perl':
    ensure => present;
  }
}

# IRC bot reporting Bugzilla bugs
class misc::irc::wikibugs {

  # Some Bugzilla product have been blessed with their own
  # log files out of the default one.
  class { '::ircecho':
     ircecho_logs   => {
        '/var/wikibugs/wikibugs.log'         => 'wikimedia-labs',
        '/var/wikibugs/wikimedia-mobile.log' => 'wikimedia-mobile',
        '/var/wikibugs/wikibugs.log'         => 'wikimedia-dev',
    },
     ircecho_nick => 'wikibugs',
  }

  include misc::irc::wikibugs::packages

  generic::systemuser { 'wikibugs': name => 'wikibugs' }

  File {
    owner   => 'wikibugs',
    group   => 'wikidev',
    mode    => '0755',
  }

  file {
    '/var/lib/wikibugs':
      ensure => directory;
    '/var/lib/wikibugs/log':
      ensure => directory;
  }

  User['wikibugs'] -> File['/var/lib/wikibugs'] -> File['/var/lib/wikibugs/log']

  git::clone { 'wikibugs' :
    directory => '/var/lib/wikibugs/bin',
    origin    => 'https://gerrit.wikimedia.org/r/p/wikimedia/bugzilla/wikibugs.git',
    owner     => wikibugs,
    group     => wikidev,
    require   => User['wikibugs'];
  }
}
