# == Class: role::ipython_notebook
#
# This Puppet role provisions IPython Notebook, a web-based data analysis
# environment based on Python. See the IPython module for more details.
#
class role::ipython_notebook {
    system::role { 'role::ipython_notebook':
        description => 'IPython Notebook',
    }

    $ipythondir = '/srv/ipython'
    $helperfile = "${ipythondir}/helpers.py"

    class { 'ipython::notebook':
        ipythondir => $ipythondir,
        exec_files => [ $helperfile ],
    }

    file { $helperfile:
        ensure => present,
    }

    # Pandas and Sympy are popular Python libraries for data analysis
    # and symbolic mathematics.
    package { [ 'python-pandas', 'python-sympy' ]:
        ensure => latest,
    }
}
