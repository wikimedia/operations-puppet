# misc/wikistats.pp
# vim: set noexpandtab :
# mediawiki statistics site

class misc::wikistats {

	system_role { 'misc::wikistats': description => 'wikistats host' }
	systemuser { wikistats: name => 'wikistats', home => '/usr/lib/wikistats', groups => [ 'wikistats' ] }
}

	# the web UI part (output)
class misc::wikistats::web ( $wikistats_host, $wikistats_ssl_cert, $wikistats_ssl_key ) {

	class {'webserver::php5': ssl => 'true'; }
	include webserver::php5-mysql

	file {
		"/etc/apache2/sites-available/${wikistats_host}":
			ensure	=> present,
			mode	=> '0444',
			owner	=> root,
			group	=> root,
			content	=> template('apache/sites/wikistats.erb');
		'/etc/apache2/ports.conf':
			ensure	=> present,
			mode	=> '0644',
			owner	=> root,
			group	=> root,
			source	=> 'puppet:///files/apache/ports.conf';
		'/var/www/wikistats':
			ensure	=> directory,
			mode	=> '0755',
			owner	=> wikistats,
			group	=> www-data;
	}

	apache_module { rewrite: name => 'rewrite' }

	apache_confd { namevirtualhost: install => 'true', name => 'namevirtualhost' }
	apache_site { no_default: name => '000-default', ensure => absent }
	apache_site { wikistats: name => $wikistats_host }

}

class misc::wikistats::packages {

	package { [
		'libhtml-treebuilder-xpath-perl',
		'libjson-xs-perl',
		'libnet-patricia-perl',
		'libtemplate-perl',
		'libweb-scraper-perl',
	]:
		ensure => 'installed',
	}

}

# the update scripts fetching data (input)
class misc::wikistats::updates {

	include misc::wikistats::packages

	#FIXME - this was used in labs in the past but is gone unfortunately
	#require misc::mariadb::server

	package { 'php5-cli': ensure => latest; }

	file { '/var/log/wikistats':
		ensure => directory,
		mode => '0664',
		owner => wikistats,
		group => wikistats,
	}

	define wikistats::cronjob() {

		$project = regsubst($name, '@.*', '\1')
		$hour = regsubst($name, '.*@', '\1')

		cron { "cron-wikistats-update-${name}":
			command => "/usr/bin/php /usr/lib/wikistats/update.php ${project} > /var/log/wikistats/update_${name}.log 2>&1",
			user => wikistats,
			hour => $hour,
			minute => 0,
			ensure => present,
		}
	}
	# update cron jobs: usage: <project prefix>@<hour>
	wikistats::cronjob { [ 'wp@0','lx@1','wt@2','ws@3','wn@4','wb@5','wq@6','os@7','gt@8','an@9','wf@10','wv@11','sc@12','ne@13','wr@14','et@15','mt@16','un@17','wx@18','mw@19','sw@20','ro@21','re@22','pa@23' ]: }

}
