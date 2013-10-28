# misc/wikistats.pp
# mediawiki statistics site

class misc::wikistats {

	system::role { 'misc::wikistats': description => 'wikistats host' }
	generic::systemuser { wikistats: name => 'wikistats', home => '/usr/lib/wikistats', groups => [ 'wikistats' ] }
}

	# the web UI part (output)
class misc::wikistats::web ( $wikistats_host, $wikistats_ssl_cert, $wikistats_ssl_key ) {

	class {'webserver::php5': ssl => true; }
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

	apache_confd { namevirtualhost: install => true, name => 'namevirtualhost' }
	apache_site { wikistats: name => $wikistats_host }

}

# the update scripts fetching data (input)
class misc::wikistats::updates {

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
	wikistats::cronjob { [ 'wp@0',  # Wikipedias
				'lx@1',  # LXDE
				'wt@2',  # Wiktionaries
				'ws@3',  # Wikisources
				'wn@4',  # Wikinews
				'wb@5',  # Wikibooks
				'wq@6',  # Wikiquotes
				'os@7',  # OpenSUSE
				'gt@8',  # Gentoo
				'an@9',  # Anarchopedias
				'wf@10', # Wikifur
				'wv@11', # Wikiversities
				'sc@12', # Scoutwikis
				'ne@13', # Neoseeker
				'wr@14', # Wikitravel
				'et@15', # EditThis
				'mt@16', # Metapedias
				'un@17', # Uncylomedias
				'wx@18', # Wikimedia Special
				'mw@19', # Mediawikis
				'sw@20', # Shoutwikis
				'wy@20', # Wikivoyages
				'ro@21', # Rodovid
				'wk@21', # Wikkii
				're@22', # Referata
				'pa@23', # Pardus
			    ]: }

}
