# == Class: role::ipython_notebook
#
# This Puppet role provisions IPython Notebook, a web-based data analysis
# environment based on Python. See the IPython module for more details.
#
class role::ipython_notebook {
    system_role { 'role::ipython_notebook':
        description => 'IPython Notebook',
    }

    $helpers_path = '/opt/ipython'
    $helpers_file = "${helpers_path}/helpers.py"

    class { 'ipython::notebook':
        exec_files => [ $helpers_file ],
        require    => File[$helpers_file],
    }

    file { $helpers_path:
        ensure => directory,
        owner  => $ipython::user,
        group  => $ipython::group,
    }

    file { $helpers_file:
        ensure => present,
        owner  => $ipython::user,
        group  => $ipython::group,
    }

    # Pandas and Sympy are popular Python libraries for data analysis
    # and symbolic mathematics.
    package { [ 'python-pandas', 'python-sympy' ]:
        ensure => latest,
    }
}
