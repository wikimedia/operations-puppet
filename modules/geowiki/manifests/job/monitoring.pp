# == Class geowiki::job::monitoring
# Checks if the geowiki files served throuh http://gp.wmflabs.org are
# up to date.
#
# Disabled for now due to restructuring of geowiki.
#
class geowiki::job::monitoring {
    require ::geowiki::job
    include ::passwords::geowiki

    $geowiki_http_user    = $passwords::geowiki::user
    $geowiki_http_pass    = $passwords::geowiki::pass
    $geowiki_http_password_file = "${::geowiki::path}/.http_password"

    file { $geowiki_http_password_file:
        owner   => $::geowiki::user,
        group   => $::geowiki::user,
        mode    => '0400',
        content => $geowiki_http_pass,
    }

    # cron job to fetch geowiki data via https://stats.wikimedia/geowiki-private (private data)
    # and checks that the files are up-to-date and within
    # meaningful ranges.
    # Disabled for T173486
    # cron { 'geowiki-monitoring':
    #     minute      => 30,
    #     hour        => 23,
    #     user        => $::geowiki::user,
    #     environment => 'MAILTO=analytics-alerts@wikimedia.org',
    #     command     => "${::geowiki::scripts_path}/scripts/check_web_page.sh --private-part-user ${geowiki_http_user} --private-part-password-file ${geowiki_http_password_file}",
    # }
}
