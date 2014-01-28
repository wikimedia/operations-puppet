class misc::beta::autoupdater {

	require misc::deployment::common_scripts

	# Parsoid JavaScript dependencies are updated on beta via npm
	package { 'npm':
		ensure => present,
	}

	file {
		# Old shell version
		"/usr/local/bin/wmf-beta-autoupdate":
			ensure => absent;
		# Python rewrite
		"/usr/local/bin/wmf-beta-autoupdate.py":
			owner => root,
			group => root,
			mode => 0555,
			require => [
				Package['git-core'],
			],
			source => 'puppet:///files/misc/beta/wmf-beta-autoupdate.py';
		"/etc/default/wmf-beta-autoupdate":
			ensure => absent;
		"/etc/init/wmf-beta-autoupdate.conf":
			ensure => absent;
	}

	# Phased out in favor of a dedicated Jenkins job running directly on the
	# beta parsoid instance.
	file { '/usr/local/bin/wmf-beta-parsoid-remote.sh':
		ensure => absent,
	}

	# Make sure wmf-beta-autoupdate can run the l10n updater as l10nupdate
	sudo_user { "mwdeploy" : privileges => [
		'ALL = (l10nupdate) NOPASSWD:/usr/local/bin/mw-update-l10n',
		'ALL = (l10nupdate) NOPASSWD:/usr/local/bin/mwscript',
		'ALL = (l10nupdate) NOPASSWD:/usr/local/bin/refreshCdbJsonFiles',
		# Some script running as mwdeploy explicily use "sudo -u mwdeploy"
		# which makes Ubuntu to request a password. The following rule
		# make sure we are not going to ask the password to mwdeploy when
		# it tries to identify as mwdeploy.
		'ALL = (mwdeploy) NOPASSWD: ALL',

		# mergeMessageFileList.php is run by mw-update-l10n as the apache user
		# since https://gerrit.wikimedia.org/r/#/c/44548/
		# Let it runs mwscript and others as apache user.
		'ALL = (apache) NOPASSWD: ALL',
	] }

	# Phase out old upstart job
	file { '/etc/init.d/wmf-beta-autoupdate':
		ensure => absent;
	}

}

# Workaround NAT traversal issue when a beta cluster instance attempt to
# connect to a beta public IP. The NAT would get the packet loss, instead
# transparently destination IP of outgoing packets to point directly to the
# private IP instance instead of the public IP.
#
# FIXME should probably be applied by default on ALL beta cluster instances.
#
# References:
#
# RT #4824   - https://rt.wikimedia.org/Ticket/Display.html?id=4824
# bug #45868 - https://bugzilla.wikimedia.org/show_bug.cgi?id=45868
class misc::beta::natfixup {

	# List out the instance public IP and private IP as described in OpenStack
	# manager interface
	#
	# FIXME ideally that should be fetched directly from OpenStack
	# configuration to make sure the iptables revwrites are always in sync with
	# the web interface :-D
	#
	$nat_mappings = {
		'deployment-cache-text1'    => { public_ip => '208.80.153.219', private_ip => '10.4.1.133' },
		'deployment-cache-upload04' => { public_ip => '208.80.153.242', private_ip => '10.4.0.211' },
		'deployment-cache-bits03'   => { public_ip => '208.80.153.243', private_ip => '10.4.0.51' },
		'deployment-eventlogging'   => { public_ip => '208.80.153.244', private_ip => '10.4.0.48' },
		'deployment-cache-mobile01' => { public_ip => '208.80.153.143', private_ip => '10.4.1.82' },
	}
	create_resources( 'misc::beta::natdestrewrite', $nat_mappings )
}

define misc::beta::natdestrewrite( $public_ip, $private_ip ) {

	include base::firewall

	# iptables -t nat -I OUTPUT --dest $public_ip -j DNAT --to-dest $private_ip
	ferm::rule { "nat_rewrite_for_${name}":
		table  => 'nat',
		chain  => 'OUTPUT',
		domain => 'ip',
		rule   => "daddr ${public_ip} { DNAT to ${private_ip}; }",
	}

}

class misc::beta::fatalmonitor {

	file { '/usr/local/bin/monitor_fatals':
		owner  => 'root',
		group  => 'root',
		mode   => '0555',
		source => 'puppet:///files/misc/beta/monitor_fatals.rb',
	}

	cron { 'beta_monitor_fatals_every_hours':
		ensure => absent,
	}

	cron { 'beta_monitor_fatals_twice_per_days':
		require => File['/usr/local/bin/monitor_fatals'],
		command => '/usr/local/bin/monitor_fatals',
		user    => nobody,
		minute  => 0,
		hour    => ['0','12']
	}
}


class misc::beta::sync-site-resources {
	file { "/usr/local/bin/sync-site-resources":
		ensure => present,
		owner => root,
		group => root,
		mode => 0555,
		source => "puppet:///files/misc/beta/sync-site-resources"
	}

	cron { "sync-site-resources":
		command => "/usr/local/bin/sync-site-resources >/dev/null 2>&1",
		require => File["/usr/local/bin/sync-site-resources"],
		hour => 12,
		user => apache,
		ensure => present,
	}
}
