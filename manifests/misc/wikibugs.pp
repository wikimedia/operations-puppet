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

<<<<<<< HEAD
	# We are an IRC bot!

	# Some Bugzilla product have been blessed with their own log files out of the
	# default one. Values are hardcoded in the Wikibugs perl script
	$ircecho_logbase = '/var/lib/wikibugs/logs'
	$ircecho_logs = {
		"${ircecho_logbase}/wikimedia-labs.log"           => '#wikimedia-labs',
		"${ircecho_logbase}/wikimedia-mobile.log"         => '#wikimedia-mobile',
		"${ircecho_logbase}/wikimedia-dev.log"            => '#wikimedia-dev',
	}

	$ircecho_nick = 'wikibugs'
	$ircecho_server = 'chat.freenode.net'

	include misc::ircecho
	include misc::irc::wikibugs::packages

	systemuser { 'wikibugs': name => 'wikibugs' }

	file {
		'/var/lib/wikibugs':
			ensure => directory,
			owner  => wikibugs,
			group => wikidev,
			mode  => '0755';
		'/var/lib/wikibugs/log':
			ensure => directory,
			owner  => wikibugs,
			group => wikidev,
			mode  => '0775',
			require => User['wikibugs'];
	}

	git::clone { 'wikibugs' :
		directory => '/var/lib/wikibugs/bin',
		origin => 'https://gerrit.wikimedia.org/r/p/wikimedia/bugzilla/wikibugs.git',
		owner => wikibugs,
		group => wikidev,
		require => User['wikibugs'];
	}
=======
  # We are an IRC bot!

  # Some Bugzilla product have been blessed with their own log files out of the
  # default one. Values are hardcoded in the Wikibugs perl script
  $ircecho_logbase = '/var/lib/wikibugs/logs'
  $ircecho_logs = {
    "${ircecho_logbase}/wikimedia-labs.log"           => '#wikimedia-labs',
    "${ircecho_logbase}/wikimedia-mobile.log"         => '#wikimedia-mobile',
    "${ircecho_logbase}/wikimedia-dev.log"            => '#wikimedia-dev',
  }

  $ircecho_nick = 'wikibugs'
  $ircecho_server = 'chat.freenode.net'

  include misc::ircecho
  include misc::irc::wikibugs::packages

  systemuser { 'wikibugs': name => 'wikibugs' }

  File {
    owner   => wikibugs,
    group   => wikidev,
    mode    => '0755',
    require => User['wikibugs'];
  }

  file {
    '/var/lib/wikibugs':
      ensure => directory;
    '/var/lib/wikibugs/bin':
      ensure => directory;
    '/var/lib/wikibugs/log':
      ensure => directory;
  }

  git::clone { 'wikibugs' :
    directory => '/var/lib/wikibugs/bin',
    origin    => 'https://gerrit.wikimedia.org/r/p/wikimedia/bugzilla/wikibugs.git',
    owner     => wikibugs,
    group     => wikidev,
    require   => User['wikibugs'];
  }
>>>>>>> f6b58a4... wikibugs: also need /var/lib/wikibugs/bin dir, summarize needed dirs,
}
