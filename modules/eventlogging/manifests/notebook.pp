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
class eventlogging::notebook(
	$ipython_dir = '/var/lib/ipython',
	$ipython_profile = 'nbserver',
	$ipython_user = 'ipython',
	$notebook_dir = '/var/lib/ipython/notebooks'
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
		mode    => '0660',
		require => Systemuser[$ipython_user],
	}

	exec { "ipython profile create ${ipython_profile}":
		creates     => "${ipython_dir}/profile_${ipython_profile}",
		environment => "IPYTHONDIR=${ipython_dir}",
		user        => $ipython_user,
		require     => [ Package['ipython-notebook'], Systemuser[$ipython_user] ],
	}

	file { '/etc/supervisor/conf.d/notebook.conf':
		content => template('eventlogging/notebook.conf.erb'),
		require => [ Package['ipython-notebook'], File[$notebook_dir] ],
		notify  => Service['supervisor'],
		mode    => '0444',
	}

}
