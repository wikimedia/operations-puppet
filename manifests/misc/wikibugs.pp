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
	$ircecho_infile = '/var/lib/wikibugs/logs/wikimedia-labs.log:#wikimedia-labs;/var/lib/wikibugs/logs/wikimedia-mobile.log:#wikimedia-mobile;/var/lib/wikibugs/logs/mediawiki-parsoid.log:#mediawiki-parsoid;/var/lib/wikibugs/logs/mediawiki.log:#mediawiki'
	$ircecho_nick = "wikibugs"
	# Add channels defined in $ircecho_infile:
	$ircecho_chans = '#wikimedia-labs,#wikimedia-mobile,#mediawiki,#mediawiki-parsoid'
	$ircecho_server = 'irc.freenode.net'

	include misc::ircecho

	systemuser { wikibugs: name => 'wikibugs' }

	file {
		"/var/lib/wikibugs/log":
			owner  => wikibugs,
			group => wikidev,
			mode  => 0775,
			require => User['wikibugs'];
	}

	git::clone { 'wikibugs':
		require => [ Package[ 'libemail-mime-perl' ], File[ '/var/lib/wikibugs' ] ],
		directory => '/var/lib/wikibugs/script/wikibugs',
		branch => 'master',
		timeout => 1800,
		depth => 1,
		ensure => $keep_up_to_date + {
			true => latest,
			default => present
		},
		origin => 'https://gerrit.wikimedia.org/r/p/wikimedia/bugzilla/wikibugs.git';
	}
}
