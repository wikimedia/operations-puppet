# graphite - https://graphite.wikimedia.org/

class misc::graphite {
	system::role { "misc::graphite": description => "graphite and carbon services" }

	include webserver::apache2

	package { [ "python-libxml2", "python-sqlite", "python-sqlitecachec", "python-setuptools", "libapache2-mod-python", "libcairo2", "python-cairo", "python-simplejson", "python-django", "python-django-tagging", "python-twisted", "python-twisted-runner", "python-twisted-web", "memcached", "python-memcache" ]:
		ensure => present;
	}

	if versioncmp($::lsbdistrelease, "12.04") >= 0 {
		package { [ "python-carbon", "python-graphite-web", "python-whisper" ]:
			ensure => "0.9.10";
		}
	}

	file {
		[ "/a/graphite", "/a/graphite/conf", "/a/graphite/modules", "/a/graphite/storage" ]:
			owner => "www-data",
			group => "www-data",
			mode => 0755,
			ensure => directory;
		"/etc/apache2/sites-available/graphite":
			owner => "root",
			group => "root",
			mode => 0444,
			source => "puppet:///files/graphite/apache.conf";
		"/a/graphite/conf/carbon.conf":
			owner => "root",
			group => "root",
			mode => 0444,
			source => "puppet:///files/graphite/carbon.conf";
		"/a/graphite/conf/dashboard.conf":
			owner => "root",
			group => "root",
			mode => 0444,
			source => "puppet:///files/graphite/dashboard.conf";
		"/a/graphite/conf/storage-schemas.conf":
			owner => "root",
			group => "root",
			mode => 0444,
			source => "puppet:///files/graphite/storage-schemas.conf";
		"/a/graphite/conf/storage-aggregation.conf":
			owner => "root",
			group => "root",
			mode => 0444,
			source => "puppet:///files/graphite/storage-aggregation.conf";
		"/etc/sysctl.d/99-big-rmem.conf":
			owner => "root",
			group => "root",
			mode => 0444,
			content => "
net.core.rmem_max = 536870912
net.core.rmem_default = 536870912
";
	}

	apache_module { python: name => "python" }
	apache_site { graphite: name => "graphite" }

	include network::constants

	#varnish::instance { "graphite":
	#	name => "",
	#	vcl => "graphite",
	#	port => 81,
	#	admin_port => 6082,
	#	storage => "-s malloc,256M",
	#	backends => [ 'localhost' ],
	#	directors => { 'backend' => [ 'localhost' ] },
	#	vcl_config => {
	#		'retry5xx' => 0
	#	},
	#	backend_options => {
	#		'port' => 80,
	#		'connect_timeout' => "5s",
	#		'first_byte_timeout' => "35s",
	#		'between_bytes_timeout' => "4s",
	#		'max_connections' => 100,
	#		'probe' => "options",
	#	},
	#	xff_sources => $network::constants::all_networks
	#}
}


# == Class: misc::graphite::navtiming
#
# Captures NavigationTiming event and send them to StatsD / Graphite.
# See https://meta.wikimedia.org/wiki/Schema:NavigationTiming &
# http://www.mediawiki.org/wiki/Extension:NavigationTiming
#
class misc::graphite::navtiming {
    $endpoint = 'tcp://vanadium.eqiad.wmnet:8600'
    $statsd_host = '127.0.0.1'
    $statsd_port = 8125

    file { '/a/graphite/modules/navtiming.py':
        source => 'puppet:///files/graphite/modules/navtiming.py',
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
        notify => Service['navtiming'],
    }

    file { '/usr/local/share/statsd/mediansOnlyFilter.js':
        content => 'exports.filter = function ( m ) { return /median$/.test( m.name ) && m; };',
        before  => Service['statsd'],
    }

    file { '/etc/init/navtiming.conf':
        content => template('graphite/modules/navtiming.conf.erb'),
        notify  => Service['navtiming'],
    }

    service { 'navtiming':
        ensure   => running,
        provider => upstart,
    }

    class { '::statsd':
        settings => {
            flushInterval    => 5 * 60 * 1000,  # 5 min.
            backends         => [ 'ganglia' ],
            gangliaFilters   => [ '/usr/local/share/statsd/mediansOnlyFilter.js' ],
            address          => $statsd_host,
            percentThreshold => [ 95 ],
            # Show frequency distribution of client-side latency times.
            # See <http://tinyurl.com/statsd-histograms>.
            histogram        => [
                {
                    metric => 'browser',
                    bins   => [ 100, 500, 1000, 2000, 5000, 'inf' ],
                },
            ],
            gangliaHost      => $::ganglia::mcast_address,
            gangliaMulticast => true,
            gangliaSpoofHost => 'client-side',
        },
    }
}
