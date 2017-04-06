
# == Class geowiki::private_data
# Makes sure the geowiki's data-private repository is available.
#
class geowiki::private_data {
    require ::geowiki
    include ::geowiki::params

    file { $::geowiki::params::private_data_bare_path:
        ensure => directory,
        owner  => $::geowiki::params::user,
        group  => $::geowiki::params::user,
        mode   => '0640',
    }

    # The bare repository lives on private_data_bare_host, so it's available there directly.
    # It only needs backup (as the repo is not living in gerrit)
    # Other hosts need to rsync it over
    if $::fqdn == $::geowiki::params::private_data_bare_host {
        include ::profile::backup::host
        backup::set { 'a-geowiki-data-private-bare': }
    }
    else {
        cron { 'geowiki data-private bare sync':
            command => "/usr/bin/rsync -rt --delete rsync://${::geowiki::params::private_data_bare_host}${::geowiki::params::private_data_bare_path}/ ${::geowiki::params::private_data_bare_path}/",
            require => File[$::geowiki::params::private_data_bare_path],
            user    => $::geowiki::params::user,
            hour    => '17',
            minute  => '0',
            before  => Git::Clone['geowiki-data-private'],
        }
    }

    git::clone { 'geowiki-data-private':
        ensure    => 'latest',
        directory => $::geowiki::params::private_data_path,
        origin    => "file://${::geowiki::params::private_data_bare_path}",
        owner     => $::geowiki::params::user,
        group     => 'www-data',
        mode      => '0750',
        umask     => '027',
        require   => File[$::geowiki::params::private_data_bare_path],
    }
}
