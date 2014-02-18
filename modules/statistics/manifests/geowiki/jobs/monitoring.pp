# == Class statistics::geowiki::jobs::monitoring
# Checks if the geowiki files served throuh http://gp.wmflabs.org are
# up to date.
#
# Disabled for now due to restructuring of geowiki.
#
class statistics::geowiki::jobs::monitoring {
    require statistics::geowiki,
        passwords::geowiki

    $geowiki_user         = $statistics::geowiki::geowiki_user
    $geowiki_base_path    = $statistics::geowiki::geowiki_base_path
    $geowiki_scripts_path = $statistics::geowiki::geowiki_scripts_path

    $geowiki_http_user = $passwords::geowiki::user
    $geowiki_http_pass = $passwords::geowiki::pass

    $geowiki_http_password_file = "${geowiki_base_path}/.http_password"

    file { $geowiki_http_password_file:
        owner   => $geowiki_user,
        group   => $geowiki_user,
        mode    => '0400',
        content => $geowiki_http_pass,
    }

    # cron job to fetch geowiki data via http://gp.wmflabs.org/ (public data)
    # and https://stats.wikimedia/geowiki-private (private data)
    # and checks that the files are up-to-date and within
    # meaningful ranges.
    cron { 'geowiki-monitoring':
        minute  => 30,
        hour    => 21,
        user    => $geowiki_user,
        command => "${geowiki_scripts_path}/scripts/check_web_page.sh --private-part-user ${geowiki_http_user} --private-part-password-file ${geowiki_http_password_file}",
    }
}

