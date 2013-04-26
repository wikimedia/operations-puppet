define tcpircbot::instance(
	$channel,
	$password,
	$nickname    = $title,
	$server_host = 'chat.freenode.net',
	$server_port = 7000,
	$ssl         = true,
	$max_clients = 5,
	$listen_port = 9200,
) {
	include tcpircbot

	file { "${tcpircbot::dir}/${title}.json":
		ensure  => present,
		content => template('tcpircbot/tcpircbot.json.erb'),
		require => User[$tcpircbot::user],
	}

	file { "/etc/init/tcpircbot-${title}.conf":
		ensure  => present,
		content => template('tcpircbot/tcpircbot.conf.erb'),
	}

	file { "/etc/init.d/tcpircbot-${title}":
		ensure => link,
		target => '/lib/init/upstart-job',
	}

	service { "tcpircbot-${title}":
		ensure   => running,
		provider => 'upstart',
		require  => [
			Package['python-irclib'],
			File["${tcpircbot::dir}/${title}.json"],
			File["/etc/init/tcpircbot-${title}.conf"]
		],
	}
}
