
# == Class geowiki::private_data
# Makes sure the geowiki's data-private repository is available.
#
class geowiki::private_data {
    require ::geowiki

    file { $::geowiki::private_data_bare_path:
        ensure => directory,
        owner  => $::geowiki::user,
        group  => $::geowiki::user,
        mode   => '0640',
    }

    # The bare repository lives on private_data_bare_host, so it's available there directly.
    # It only needs backup (as the repo is not living in gerrit)
    # Other hosts need to rsync it over
    if $::fqdn == $::geowiki::private_data_bare_host {
        include ::profile::backup::host
        # TODO: fix bakcup set path to use /srv after stat1002 is gone.
        backup::set { 'a-geowiki-data-private-bare': }
    }
    else {
        cron { 'geowiki data-private bare sync':
            command => "/usr/bin/rsync -rt --delete rsync://${::geowiki::private_data_bare_host}${::geowiki::private_data_bare_path}/ ${::geowiki::private_data_bare_path}/",
            require => File[$::geowiki::private_data_bare_path],
            user    => $::geowiki::user,
            hour    => '17',
            minute  => '0',
            before  => Git::Clone['geowiki-data-private'],
        }
    }

    git::clone { 'geowiki-data-private':
        ensure    => 'latest',
        directory => $::geowiki::private_data_path,
        origin    => "file://${::geowiki::private_data_bare_path}",
        owner     => $::geowiki::user,
        group     => 'www-data',
        mode      => '0750',
        umask     => '027',
        require   => File[$::geowiki::private_data_bare_path],
    }
}
