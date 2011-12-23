# misc/wikistats.pp
# mediawiki statistics site

class misc::wikistats {
	system_role { 'misc::wikistats': description => 'wikistats host' }
	systemuser { wikistats: name => 'wikistats', home => '/var/lib/wikistats', groups => [ 'wikistats' ] }

	# the web UI part (output)
	class web {

		class {'generic::webserver::php5': ssl => 'true'; }

			$wikistats_host = '${instancename}.${domain}'
			$wikistats_ssl_cert = '/etc/ssl/certs/star.wmflabs.pem'
			$wikistats_ssl_key = '/etc/ssl/private/star.wmflabs.key'

		file {
			'/etc/apache2/sites-available/wikistats.wmflabs.org':
				ensure	=> present,
				mode	=> '0444',
				owner	=> root,
				group	=> root,
				content	=> template('apache/sites/wikistats.wmflabs.org.erb');
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
			'/var/www/wikistats/index.php':
				ensure	=> present,
				mode	=> '0440',
				owner	=> wikistats,
				group	=> www-data,
				source	=> 'puppet:///files/misc/wikistats/index.php',
				require	=> File['/var/www/wikistats'];
		}

		apache_module { rewrite: name => 'rewrite' }

		apache_confd { namevirtualhost: install => 'true', name => 'namevirtualhost' }
		apache_site { no_default: name => '000-default', ensure => absent }
		apache_site { wikistats: name => 'wikistats.wmflabs.org' }

	}

	# the update scripts fetching data (input)
	class updates {

		include generic::mysql::client
		package { 'php5-cli': ensure => latest; }
	}

}

