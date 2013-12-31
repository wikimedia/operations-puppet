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

class misc::irc::wikibugs {

  # We are an IRC bot!

  # Some Bugzilla product have been blessed with their own log files out of the
  # default one. Values are hardcoded in the Wikibugs perl script
  $ircecho_logbase = '/var/wikibugs'
  $ircecho_logs = {
    "${ircecho_logbase}/wikibugs.log"         => '#wikimedia-labs',
    "${ircecho_logbase}/wikimedia-mobile.log" => '#wikimedia-mobile',
    "${ircecho_logbase}/wikibugs.log"         => '#wikimedia-dev',
  }

  $ircecho_nick = 'wikibugs'
  $ircecho_server = 'chat.freenode.net'

  include role::echoirc
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
