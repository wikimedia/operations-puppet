# OpenStack zuul
#
# A Jenkins/Gerrit gateway written in python. This is a drop in replacement
# for Jenkins "Gerrit Trigger" plugin.
#
# Lamely copied from openstack-ci/openstack-ci-puppet repository, replaced
# vcsrepo by our git::clone class.
#

# == Class: zuul
class zuul (
    $jenkins_server,
    $jenkins_user,
    $jenkins_apikey,
    $gerrit_server,
    $gerrit_user,
    $gerrit_baseurl = 'https://gerrit.wikimedia.org/r',
    $url_pattern,
    $status_url = "https://${::fqdn}/zuul/status",
    $git_source_repo = 'https://gerrit.wikimedia.org/r/p/integration/zuul.git',
    $git_dir = '/var/lib/zuul/git',
    $push_change_refs,
) {

	# Dependencies as mentionned in zuul:tools/pip-requires
	$packages = [
			'python-yaml',
			'python-webob',
			'python-daemon',
			'python-lockfile',
			'python-paramiko',
			'python-jenkins',
			'python-paste',

			# GitPython at least 0.3.2RC1 which is neither in Lucid nor in Precise
			# We had to backport it and its dependencies from Quantal:
			'python-git',
			'python-gitdb',
			'python-async',
			'python-smmap',

			'python-extras',  # backported in Precise (bug 47122)
			'python-statsd',

			'python-setuptools',
	]

	package { $packages:
		ensure => present,
	}

	# We have packaged the python voluptuous module under
	# operations/debs/python-voluptuous. Zuul does not work
	# AT ALL with version 0.7 so make sure we have 0.6.x
	package { 'python-voluptuous':
		ensure => '0.6.1-4',
	}

	# Used to be in /var/lib/git/zuul but /var/lib/git can be used
	# to replicate git bare repositories.
	$zuul_source_dir = '/usr/local/src/zuul'

	git::clone { 'integration/zuul':
		ensure => present,
		directory => $zuul_source_dir,
		origin => $git_source_repo,
		branch => 'master',
	}

	exec { 'install_zuul':
		command => 'python setup.py install',
		cwd => $zuul_source_dir,
		path => '/bin:/usr/bin',
		refreshonly => true,
		subscribe => Git::Clone['integration/zuul'],
		require => Package['python-setuptools'],
	}

	file { '/etc/zuul':
		ensure => directory,
	}

	# TODO: We should put in  notify either Service['zuul'] or Exec['zuul-reload']
	#       at some point, but that still has some problems.
	file { '/etc/zuul/zuul.conf':
		ensure => present,
		owner => 'jenkins',
		mode => '0400',
		content => template('zuul/zuul.conf.erb'),
		require => [
			File['/etc/zuul'],
			Package['jenkins'],
		],
	}

	file { '/var/log/zuul':
		ensure => directory,
		owner => 'jenkins',
		require => Package['jenkins'],
	}

	file { '/var/run/zuul':
		ensure => directory,
		owner => 'jenkins',
		require => Package['jenkins'],
	}

	file { '/var/lib/zuul':
		ensure => directory,
		owner => 'jenkins',
		require => Package['jenkins'],
	}

	file { $git_dir:
		ensure => directory,
		owner => 'jenkins',
		require => Package['jenkins'],
	}

	file { '/etc/init.d/zuul/':
		ensure => present,
		owner => 'root',
		group => 'root',
		mode => '0555',
		source => 'puppet:///modules/zuul/zuul.init',
	}

	exec { 'zuul-reload':
		command => '/etc/init.d/zuul reload',
		require => File['/etc/init.d/zuul'],
		refreshonly => true,
	}

	service { 'zuul':
		name => 'zuul',
		enable => true,
		hasrestart => true,
		require => File['/etc/init.d/zuul'],
	}
}
