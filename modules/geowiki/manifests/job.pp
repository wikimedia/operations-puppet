# == Class geowiki::job
# Base class for other geowiki::job::* classes.
#
class geowiki::job {
    require ::geowiki

    include ::geowiki::params
    include ::geowiki::mysql_conf
    include geoip

    # This is not a complete list of
    # python packages that geowiki requires.
    # It will need many more that were manually
    # installed by Evan Rosen when he originally
    # wrote geowiki.
    require_package('python-pandas')
    require_package('python-geoip')
    require_package('python-mysqldb')

    file { $::geowiki::params::log_path:
        ensure => 'directory',
        owner  => $::geowiki::params::user,
        group  => $::geowiki::params::user,
    }
}
