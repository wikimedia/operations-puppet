# == Class: eventlogging::notebook
#
# Configures an integrated, web-based numeric computation environment
# (like Mathematica), based on PyLab and IPython Notebook.
# See <http://ipython.org/ipython-doc/dev/interactive/htmlnotebook.html>
# and <http://www.scipy.org/PyLab>.
#
# === Parameters
#
# [*ipython_dir*]
#   IPython working directory.
#
# [*ipython_profile*]
#   Name of IPython profile to create.
#
# [*ipython_user*]
#   Create this user account and run IPython as this user.
#
# [*notebook_dir*]
#   Specifies where IPython should archive notebooks.
#
# [*notebook_ip*]
#   Interface on which the notebook server will listen (or '*' for all
#   interfaces).
#
# [*notebook_port*]
#   The port the notebook server will listen on.
#
# [*exec_files*]
#   Array of Python files to execute at start of Notebook session.
#
class eventlogging::notebook(
	$ipython_dir = '/var/lib/ipython',
	$ipython_profile = 'nbserver',
	$ipython_user = 'ipython',
	$notebook_dir = '/var/lib/ipython/notebooks',
	$notebook_ip = '*',
	$notebook_port = 8888,
	$exec_files = []
) {

	package { [
		'ipython-notebook',
		'python-matplotlib',
		'python-numpy',
		'python-pandas',
		'python-pexpect',
		'python-scipy',
	]:
		ensure => latest,
	}

	systemuser { $ipython_user:
		name => $ipython_user,
		home => $ipython_dir,
	}

	file { $notebook_dir:
		ensure  => directory,
		owner   => $ipython_user,
		group   => $ipython_user,
		mode    => '0664',
		require => Systemuser[$ipython_user],
	}

	exec { "Create IPython profile ${ipython_profile}":
		command     => "ipython profile create ${ipython_profile} --ipython-dir=\"${ipython_dir}\"",
		creates     => "${ipython_dir}/profile_${ipython_profile}",
		environment => "IPYTHONDIR=${ipython_dir}",
		user        => $ipython_user,
		require     => [ Package['ipython-notebook'], Systemuser[$ipython_user] ],
	}

	file { "Configure IPython profile ${ipython_profile}":
		path    => "${ipython_dir}/profile_${ipython_profile}/ipython_notebook_config.py",
		content => template('eventlogging/ipython_notebook_config.py.erb'),
		require => Exec["Create IPython profile ${ipython_profile}"],
		owner   => $ipython_user,
		group   => $ipython_user,
		mode    => '0444',
	}

	file { '/etc/supervisor/conf.d/notebook.conf':
		content => template('eventlogging/notebook.conf.erb'),
		require => [ Package['ipython-notebook'], File[$notebook_dir] ],
		notify  => Service['supervisor'],
		mode    => '0444',
	}

}
