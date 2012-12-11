# Installs a logbot.  Channel, name, etc. are configurable.
#  at the moment, only one bot per instance, and only one
#  log page per bot will work.
class bots::logbot( $ensure = 'present',
			     $enable_projects = "False",
			     $targets = '()',
			     $nick = '("anonbot")',
			     $nickserv = 'nickserv',
			     # For security reasons, nick_password, wiki_user and wiki_pass
			     #  are not puppetized.  Instead, insert them into this
			     #  file and it will be included in the config, python-style.
			     $password_include_file = '',
			     $network = 'irc.freenode.net',
			     $port = 6667,
			     $author_map = '{}',
			     $title_map = '{}',
			     $wiki_connection = '("https","labsconsole.wikimedia.org")',
			     $wiki_path = "/w/",
			     $wiki_user = "anon",
			     $wiki_domain = "",
			     $wiki_page = "",
			     $wiki_header_depth = 3,
                             $wiki_category = "SAL") {

	package { adminbot:
		ensure => $ensure;
	}

	file {
		"/etc/adminbot/config.py":
			mode => 644,
			owner => root,
			group => root,
			content => template('adminbot/config.py.erb'),
			ensure => present;
		"/var/run/adminbot":
			mode => 644,
			owner => adminbot,
			group => root,
			ensure => directory;
	}
}
