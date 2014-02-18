# == Class misc::statistics::geowiki::data::private_bare::sync
# Makes sure the geowiki's bare data-private repository is available.
#
class statistics::geowiki::data::private_bare {
    require statistics::geowiki

    $geowiki_user                   = $statistics::geowiki::geowiki_user
    $geowiki_base_path              = $statistics::geowiki::geowiki_base_path
    $geowiki_private_data_bare_path = $statistics::geowiki::private_data_bare_path
    $geowiki_private_data_bare_host = 'stat1'
    $geowiki_private_data_bare_host_fqdn = "${geowiki_private_data_bare_host}.wikimedia.org"

    file { $geowiki_private_data_bare_path:
        ensure => 'directory',
        owner  => $geowiki_user,
        group  => $geowiki_user,
        mode   => '0640',
    }

    # The bare repository lives on stat1, so it's available there directly.
    # It only needs backup (as the repo is not living in gerrit)
    # Other hosts need to rsync it over
    if $::hostname == $geowiki_private_data_bare_host {
        include backup::host
        backup::set { 'a-geowiki-data-private-bare': }
    } else {
        cron { 'geowiki data-private bare sync':
            command => "/usr/bin/rsync -rt --delete rsync://${geowiki_private_data_bare_host_fqdn}${geowiki_private_data_bare_path}/${geowiki_private_data_bare_path}/",
            require => File[$geowiki_private_data_bare_path],
            user    => $geowiki_user,
            hour    => '17',
            minute  => '0',
        }
    }
}
