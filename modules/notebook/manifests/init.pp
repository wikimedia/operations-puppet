# == Class: notebook
#
# Configures an integrated, web-based numeric computation environment
# (like Mathematica), based on PyLab and IPython Notebook.
# See <http://ipython.org/ipython-doc/dev/interactive/htmlnotebook.html>
# and <http://www.scipy.org/PyLab>.
#
# === Parameters
#
# [*ipython_dir*]
#   IPython working directory. Equivalent to the IPYTHONHOME environment
#   variable. Defaults to '/srv/ipython'.
#
# [*ipython_profile*]
#   Name of IPython profile to create (default: 'nbserver').
#
# [*ipython_user*]
#   Run IPython Notebook as this user (default: 'ipython'). The account (and a
#   group of the same name) will be created, with $ipython_dir as its home.
#
# [*matplotlib_dir*]
#   This is the directory used to store user customizations to matplotlib, as
#   well as some caches to improve performance. Equivalent to the MPLCONFIGDIR
#   environment variable. Defaults to "$ipython_dir/matplotlib".
#
# [*notebook_dir*]
#   Specifies where IPython should store notebooks (default:
#   "$ipython_dir/notebooks").
#
# [*notebook_ip*]
#   Interface on which the notebook server will listen, or '*' for all
#   interfaces (default: '*').
#
# [*notebook_port*]
#   The port the notebook server will listen on (default: 8888).
#
# [*exec_files*]
#   Array of fully qualified paths to Python files to execute at start of
#   Notebook session (default: none).
#
#
# === Examples
#
#  class { 'notebook':
#    notebook_port => 9000,
#    exec_files    => [ '/srv/ipython/notebook_init.py' ],
#  }
#
# === Authors
#
# Ori Livneh <ori@wikimedia.org>
#
# === Copyright
#
# Copyright 2013 Wikimedia Foundation
#
class notebook(
	$ipython_dir = '/srv/ipython',
	$ipython_profile = 'nbserver',
	$ipython_user = 'ipython',
	$matplotlib_dir = 'UNSET',
	$notebook_dir = 'UNSET',
	$notebook_ip = '*',
	$notebook_port = 8888,
	$exec_files = []
) {

	$notebook_dir_real = $notebook_dir ? {
		'UNSET' => "${ipython_dir}/notebooks",
		default => $notebook_dir,
	}

	$matplotlib_dir_real = $matplotlib_dir ? {
		'UNSET' => "${ipython_dir}/matplotlib",
		default => $matplotlib_dir,
	}

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

	group { $ipython_user:
		ensure => present,
	}

	user { $ipython_user:
		ensure     => present,
		gid        => $ipython_user,
		shell      => '/bin/false',
		home       => $ipython_dir,
		managehome => true,
		system     => true,
		comment    => 'IPython Notebook',
	}

	file { $notebook_dir_real:
		ensure  => directory,
		owner   => $ipython_user,
		group   => $ipython_user,
		mode    => '0775',
		require => User[$ipython_user],
	}

	file { $matplotlib_dir_real:
		ensure  => directory,
		owner   => $ipython_user,
		group   => $ipython_user,
		mode    => '0775',
		require => User[$ipython_user],
	}

	exec { "Create IPython profile ${ipython_profile}":
		command     => "/usr/bin/ipython profile create ${ipython_profile}",
		creates     => "${ipython_dir}/profile_${ipython_profile}",
		environment => "IPYTHONDIR=${ipython_dir}",
		user        => $ipython_user,
		require     => [ Package['ipython-notebook'], User[$ipython_user] ],
	}

	file { "Configure IPython profile ${ipython_profile}":
		path    => "${ipython_dir}/profile_${ipython_profile}/ipython_notebook_config.py",
		content => template('notebook/ipython_notebook_config.py.erb'),
		require => Exec["Create IPython profile ${ipython_profile}"],
		owner   => $ipython_user,
		group   => $ipython_user,
		mode    => '0444',
	}

	file { '/etc/init.d/ipython-notebook':
		ensure  => link,
		target  => '/lib/init/upstart-job',
		require => File["Configure IPython profile ${ipython_profile}"],
	}

	file { '/etc/init/ipython-notebook.conf':
		content => template('notebook/ipython-notebook.conf.erb'),
		require => File['/etc/init.d/ipython-notebook'],
	}

	service { 'IPython Notebook service':
		ensure    => running,
		provider  => 'upstart',
		subscribe => File['/etc/init/ipython-notebook.conf'],
		name      => 'ipython-notebook',
	}
}
