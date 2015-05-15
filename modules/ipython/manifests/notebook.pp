# == Class: ipython::notebook
#
# Configures an integrated, web-based numeric computation environment
# (like Mathematica), based on PyLab and IPython Notebook.
# See <http://ipython.org/ipython-doc/dev/interactive/htmlnotebook.html>
# and <http://www.scipy.org/PyLab>.
#
# === Parameters
#
# [*profile*]
#   Name of IPython profile to create (default: 'nbserver').
#
# [*user*]
#   Run the IPython Notebook service as this user. Defaults to 'ipython'.
#
# [*group*]
#   Run the IPython Notebook service under this group's gid.
#   Defaults to 'ipython'.
#
# [*ipythondir*]
#   Same as the IPYTHONDIR environment variable. The base folder for IPython
#   profiles and data.
#
# [*mplconfigdir*]
#   This is the directory used to store user customizations to matplotlib, as
#   well as some caches to improve performance. Equivalent to the MPLCONFIGDIR
#   environment variable. Defaults to "$ipythondir/matplotlib".
#
# [*notebookdir*]
#   Directory where IPython should store notebooks.
#   Default: "$ipythondir/notebooks".
#
# [*ip*]
#   Interface on which the Notebook server will listen, or '*' for all
#   interfaces (default: '*').
#
# [*port*]
#   The port the Notebook server will listen on (default: 8888).
#
# [*certfile*]
#   Fully qualified path to your SSL certificate's .pem file. If
#   unspecified, the server will not be configured for SSL.
#
# [*password*]
#   If specified, the web interface will require users to authenticate
#   using this shared secret key. By default, the server does not
#   attempt to authenticate users.
#
# [*exec_files*]
#   Array of fully qualified paths to Python files to execute at start of
#   Notebook session (default: none).
#
class ipython::notebook(
    $profile      = 'nbserver',
    $user         = $ipython::user,
    $group        = $ipython::group,
    $ipythondir   = $ipython::ipythondir,
    $mplconfigdir = "${ipython::ipythondir}/matplotlib",
    $notebookdir  = "${ipython::ipythondir}/notebooks",
    $port         = 8888,
    $ip           = '*',
    $certfile     = undef,
    $password     = undef,
    $exec_files   = []
) inherits ipython {

    ipython::profile { $profile: }

    package { [ 'ipython-notebook', 'python-matplotlib', 'python-scipy' ]:
        ensure => latest,
    }

    file { $notebookdir:
        ensure => directory,
        owner  => $user,
        group  => $group,
        mode   => '0775',
    }

    file { $mplconfigdir:
        ensure => directory,
        owner  => $user,
        group  => $group,
        mode   => '0775',
    }

    file { "${profile} notebook config":
        path    => "${ipythondir}/profile_${profile}/ipython_notebook_config.py",
        require => Ipython::Profile[$profile],
        content => template('ipython/ipython_notebook_config.py.erb'),
        owner   => $user,
        group   => $group,
        mode    => '0444',
    }

    file { '/etc/init/ipython-notebook.conf':
        content => template('ipython/ipython-notebook.conf.erb'),
        require => File["${profile} notebook config"],
    }

    service { 'ipython-notebook':
        ensure    => running,
        provider  => 'upstart',
        subscribe => File['/etc/init/ipython-notebook.conf'],
        require   => [
                    Package['ipython-notebook'],
                    File['/etc/init/ipython-notebook.conf'],
        ],
    }
}
