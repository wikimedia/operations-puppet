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
		'python-scipy',
	]:
		ensure => latest,
	}

	systemuser { 'ipython':
		name => 'ipython',
	}

}
