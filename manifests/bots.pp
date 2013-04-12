# Deprecated!  This bot is now managed by the grid engine in
#  the Tools project.
#
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
			     $network = 'chat.freenode.net',
			     $port = 6667,
			     $author_map = '{}',
			     $title_map = '{}',
			     $wiki_connection = '("https","wikitech.wikimedia.org")',
			     $wiki_path = "/w/",
			     $wiki_user = "anon",
			     # The page for viewing logs doesn't necessarily
			     # follow from wiki_path, so roles need to set it explicitly
			     # here.  This setting is only used in the bot's help message.
			     $log_url = "(unknown)",
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
			ensure => present,
			notify => Service[adminbot];
		"/var/run/adminbot":
			mode => 644,
			owner => adminbot,
			group => root,
			ensure => directory;
		"/var/log/adminbot.log":
			mode => 644,
			owner => adminbot,
			group => root,
			ensure => present
	}

	service { 'adminbot':
		name => "adminbot",
		ensure => running;
	}
}
