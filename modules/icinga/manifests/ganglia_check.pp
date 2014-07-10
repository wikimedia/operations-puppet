
# == Class icinga::ganglia::check
#
# Installs check_ganglia package and sets up symlink into
# /usr/lib/nagios/plugins.
#
# check_ganglia allows arbitrary values to be queried from ganglia and checked
# for nagios/icinga.  This is better than ganglios, as it queries gmetad's xml
# query interfaces directly, rather than downloading and mangling xmlfiles from
# each aggregator.
#
class icinga::ganglia_check {
    package { 'check-ganglia':
        ensure  => 'installed',
    }

    file { '/usr/lib/nagios/plugins/check_ganglia':
        ensure  => 'link',
        target  => '/usr/bin/check_ganglia',
        require => Package['check-ganglia'],
    }
}

