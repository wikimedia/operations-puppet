# Data analysis environment for EventLogging, based on IPython.
class eventlogging::analysis {
	package { [ 'python-pandas', 'python-sympy' ]:
		ensure => latest,
	}

	class { 'ipython::notebook':
		exec_files => [ '/var/lib/ipython/helpers/helpers.py' ],
	}
}
