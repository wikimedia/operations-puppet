# Wikibugs - homegrown perl script feed with bugzilla email notification
# will write some oneliner notification in a file to be processed by
# ircecho.
#
# Documentation: http://wikitech.wikimedia.org/view/Wikibugs
# Sourcecode: svn /trunk/tools/wikibugs
#

class misc::irc::wikibugs {

	# We are an IRC bot!

	# Some Bugzilla product have been blessed with their own log files out of the
	# default one. Values are hardcoded in the Wikibugs perl script
	$ircecho_infile = '/var/lib/wikibugs/logs/wikimedia-labs.log:#wikimedia-labs;/var/lib/wikibugs/logs/wikimedia-mobile.log:#wikimedia-mobile;/var/lib/wikibugs/logs/mediawiki.log:#mediawiki'
	$ircecho_nick = "wikibugs"
	# Add channels defined in $ircecho_infile:
	$ircecho_chans = '#wikimedia-labs,#wikimedia-mobile,#mediawiki'
	$ircecho_server = 'irc.freenode.net'

	include misc::ircecho

	systemuser { wikibugs: name => 'wikibugs' }

	file {
		"/var/lib/wikibugs/log":
			user  => wikibugs,
			group => wikidev,
			mode  => 0775,
			require => User['wikibugs'];
	}

	exec {
		"Clone wikibugs":
			command => "svn co -r115412 https://svn.wikimedia.org/svnroot/mediawiki/trunk/tools/wikibugs /var/lib/wikibugs/script",
			cwd => "/var/lib/wikibugs",
			creates => "/var/lib/wikibugs/script",
			require => [ Package['subversion', 'libemail-mime-perl'], File['/var/lib/wikibugs'] ];
	}

}
