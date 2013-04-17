# Configures an integrated, web-based numeric computation environment
# (like Mathematica), based on PyLab and IPython Notebook.
# See <http://ipython.org/ipython-doc/dev/interactive/htmlnotebook.html>
# and <http://www.scipy.org/PyLab>.
class eventlogging::notebook {

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

	systemuser { 'ipython':
		name => 'ipython',
	}

	file { '/etc/supervisor/conf.d/notebook.conf':
		source  => 'puppet:///modules/eventlogging/notebook.conf',
		require => [ Package['ipython-notebook'], Systemuser['ipython'] ],
		notify  => Service['supervisor'],
		mode    => '0444',
	}

}
