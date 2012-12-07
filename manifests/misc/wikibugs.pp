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
	$ircecho_infile = '/var/lib/wikibugs/logs/wikimedia-labs.log:#wikimedia-labs;/var/lib/wikibugs/logs/wikimedia-mobile.log:#wikimedia-mobile;/var/lib/wikibugs/logs/mediawiki-visualeditor.log:#mediawiki-visualeditor;/var/lib/wikibugs/logs/mediawiki.log:#mediawiki-feed'
	$ircecho_nick = "wikibugs"
	# Add channels defined in $ircecho_infile:
	$ircecho_chans = '#wikimedia-labs,#wikimedia-mobile,#mediawiki-visualeditor;#mediawiki-feed'
	$ircecho_server = 'irc.freenode.net'

	include misc::ircecho
	include misc::irc::wikibugs::packages

	systemuser { wikibugs: name => 'wikibugs' }

	file {
		"/var/lib/wikibugs/log":
			owner  => wikibugs,
			group => wikidev,
			mode  => 0775,
			require => User['wikibugs'];
	}

	git::clone { "wikibugs" :
		directory => "/var/lib/wikibugs/script",
		origin => "https://gerrit.wikimedia.org/r/p/wikimedia/bugzilla/wikibugs.git",
		owner => wikibugs,
		group => wikidev,
		require => File['/var/lib/wikibugs'];
	}
}
