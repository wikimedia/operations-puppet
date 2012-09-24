# OpenStack zuul
#
# A Jenkins/Gerrit gateway written in python. This is a drop in replacement
# for Jenins "Gerrit Trigger" plugin.
#
# Lamely copied from openstack-ci/openstack-ci-puppet repository, replaced
# vcsrepo by our git::clone class.
#

class zuul (
    $jenkins_server,
    $jenkins_user,
    $jenkins_apikey,
    $gerrit_server,
    $gerrit_user,
    $url_pattern
) {

	# Dependencies as mentionned in zuul:tools/pip-requires
	package { [
			'python-yaml',
			'python-paste',
			'python-webob',
			'python-paramiko',
			'python-lockfile',
			'python-daemon',

			# FIXME missing in Lucid :(
			'python-jenkins',

			# GitPython at least 0.3.2RC1 which is neither in Lucid nor in Precise
			# We had to backport it and its dependencies from Quantal:
			'python-git',
			'python-gitdb',
			'python-async',
			'python-smmap',

		]: ensure => present,
	}

	$zuul_source_dir = '/var/lib/git/integration/zuul'

	git::clone { 'integration/zuul':
		directory => $zuul_source_dir,
		origin => 'https://gerrit.wikimedia.org/r/p/integration/zuul.git',
		branch => 'dev',
		ensure => 'latest',
	}

	file { "/etc/zuul":
		ensure => "directory",
	}

	exec { "install_zuul":
		command => "python setup.py install",
		cwd => $zuul_source_dir,
		path => "/bin:/usr/bin",
		refreshonly => true,
		subscribe => Git::Clone["integration/zuul"],
	}

	file { "/etc/zuul/zuul.conf":
		owner => 'jenkins',
		mode => 0400,
		ensure => 'present',
		content => template('zuul/zuul.conf.erb'),
		require => File["/etc/zuul"],
	}

	file { "/var/log/zuul":
		ensure => "directory",
		owner => 'jenkins'
	}

	file { "/var/run/zuul":
		ensure => "directory",
		owner => 'jenkins'
	}

	file { "/var/lib/zuul":
		ensure => "directory",
		owner => 'jenkins'
	}

	file { "/var/lib/zuul/git":
		ensure => "directory",
		owner => 'jenkins'
	}

	file { "/etc/init.d/zuul/":
		owner => 'root',
		group => 'root',
		mode => 555,
		ensure => 'present',
		source => 'puppet:///modules/zuul/zuul.init',
	}

	exec { "zuul-reload":
		command => '/etc/init.d/zuul reload',
		require => File['/etc/init.d/zuul'],
		refreshonly => true,
	}

	service { 'zuul':
		name => 'zuul',
		enable => true,
		require => File['/etc/init.d/zuul'],
	}

}
