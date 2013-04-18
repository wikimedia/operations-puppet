# Configures an integrated, web-based numeric computation environment
# (like Mathematica), based on PyLab and IPython Notebook.
# See <http://ipython.org/ipython-doc/dev/interactive/htmlnotebook.html>
# and <http://www.scipy.org/PyLab>.
class eventlogging::notebook(
	$ipython_dir = '/var/lib/ipython',
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
		mode    => '0555',
		require => Systemuser[$ipython_user],
	}

	file { '/etc/supervisor/conf.d/notebook.conf':
		content => template('eventlogging/notebook.conf.erb'),
		require => [ Package['ipython-notebook'], File[$notebook_dir] ],
		notify  => Service['supervisor'],
		mode    => '0444',
	}

}
