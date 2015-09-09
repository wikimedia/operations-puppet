# == Define dashiki::instance
# Serves a dashboard built with dashiki
#
# == Parameters:
# $wikiConfig   - The wiki article to use as the dashboard configuration
# $layout       - The dashiki layout to use when building this dashboard
# $piwik        - The piwik configuration in the format "piwik_server,site_id"
# $url          - The URL to serve this dashboard at (must configure proxy manually)
#
define dashiki::instance (
    $wikiConfig = undef,
    $layout     = undef,
    $piwik      = undef,
    $url        = undef,
    $log_file   = '???',
){
    require dashiki

    if !defined(File[$base_directory]) {
        file { $base_directory:
            ensure => directory,
            owner  => $dashiki::user,
            group  => $dashiki::group,
            mode   => '0775',
        }
    }

    file { $var_directory:
        ensure => directory,
        owner  => $dashiki::user,
        group  => $dashiki::group,
        mode   => '0775',
    }

    # The upstart init conf will start server.co
    # logging to this file.
    file { $log_file:
        ensure => file,
        owner  => $dashiki::user,
        group  => $dashiki::group,
        mode   => '0775',
    }
}
