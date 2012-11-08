# Install the grunt nodejs module out of Wikimedia copy available from
# integration/gruntjs.git
#
# See documentation online at:
# https://www.mediawiki.org/wiki/Continuous_integration/grunt
class nodejs::grunt {

	require nodejs

	git::clone { 'integration/gruntjs':
		ensure => latest,
		directory => '/var/lib/git/integration/gruntjs',
		origin => 'https://gerrit.wikimedia.org/r/p/integration/gruntjs',
	}

	file { '/usr/local/bin/grunt':
		ensure => link,
		target => '/var/lib/git/integration/gruntjs/bin/grunt',
		owner => 'root',
		group => 'root',
		require => git::clone['integration/gruntjs'],
	}

}
