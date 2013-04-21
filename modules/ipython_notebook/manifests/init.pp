# == Class: ipython_notebook
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
# [*user*]
#   Run IPython Notebook as this user (default: 'ipython-notebook'). The
#   account (and a group of the same name) will be created, with $ipython_dir
#   as its home.
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
# [*ip*]
#   Interface on which the Notebook server will listen, or '*' for all
#   interfaces (default: '*').
#
# [*port*]
#   The port the Notebook server will listen on (default: 8888).
#
# [*exec_files*]
#   Array of fully qualified paths to Python files to execute at start of
#   Notebook session (default: none).
#
#
# === Examples
#
#  class { 'ipython_notebook':
#    port       => 9000,
#    exec_files => [ '/srv/ipython/notebook_init.py' ],
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
class ipython_notebook(
	$ipython_dir = '/srv/ipython',
	$ipython_profile = 'nbserver',
	$user = 'ipython-notebook',
	$matplotlib_dir = 'UNSET',
	$notebook_dir = 'UNSET',
	$ip = '*',
	$port = 8888,
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
		'python-pandas',
		'python-scipy',
		'python-sympy',
	]:
		ensure => latest,
	}

	group { $user:
		ensure => present,
	}

	user { $user:
		ensure     => present,
		gid        => $user,
		shell      => '/bin/false',
		home       => $ipython_dir,
		managehome => true,
		system     => true,
		comment    => 'IPython Notebook',
	}

	file { $notebook_dir_real:
		ensure  => directory,
		owner   => $user,
		group   => $user,
		mode    => '0775',
		require => User[$user],
	}

	file { $matplotlib_dir_real:
		ensure  => directory,
		owner   => $user,
		group   => $user,
		mode    => '0775',
		require => User[$user],
	}

	exec { "Create IPython profile ${ipython_profile}":
		command     => "/usr/bin/ipython profile create ${ipython_profile}",
		creates     => "${ipython_dir}/profile_${ipython_profile}",
		environment => "IPYTHONDIR=${ipython_dir}",
		user        => $user,
		require     => [ Package['ipython-notebook'], User[$user] ],
	}

	file { "Configure IPython profile ${ipython_profile}":
		path    => "${ipython_dir}/profile_${ipython_profile}/ipython_notebook_config.py",
		content => template('ipython_notebook/ipython_notebook_config.py.erb'),
		require => Exec["Create IPython profile ${ipython_profile}"],
		owner   => $user,
		group   => $user,
		mode    => '0444',
	}

	file { '/etc/init.d/ipython-notebook':
		ensure  => link,
		target  => '/lib/init/upstart-job',
		require => File["Configure IPython profile ${ipython_profile}"],
	}

	file { '/etc/init/ipython-notebook.conf':
		content => template('ipython_notebook/ipython-notebook.conf.erb'),
		require => File['/etc/init.d/ipython-notebook'],
	}

	service { 'IPython Notebook service':
		ensure    => running,
		provider  => 'upstart',
		subscribe => File['/etc/init/ipython-notebook.conf'],
		name      => 'ipython-notebook',
	}
}
