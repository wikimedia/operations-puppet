# misc/wikistats.pp
# mediawiki statistics site

class misc::wikistats {
	system_role { 'misc::wikistats': description => 'wikistats host' }
	systemuser { wikistats: name => 'wikistats', home => '/var/lib/wikistats', groups => [ 'project-wikistats' ] }

	# the web UI part (output)
	class web {

		class {'webserver::php5': ssl => 'true'; }
		include webserver::php5-mysql

		$wikistats_host = "wikistats.wmflabs.org"
		$wikistats_ssl_cert = '/etc/ssl/certs/star.wmflabs.org.pem'
		$wikistats_ssl_key = '/etc/ssl/private/star.wmflabs.org.key'
		$wikistats_ssl_cacert = '/etc/ssl/certs/wmf-labs.pem'

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
		}

		apache_module { rewrite: name => 'rewrite' }

		apache_confd { namevirtualhost: install => 'true', name => 'namevirtualhost' }
		apache_site { no_default: name => '000-default', ensure => absent }
		apache_site { wikistats: name => 'wikistats.wmflabs.org' }

	}

	# the update scripts fetching data (input)
	class updates {

		require misc::mariadb::server

		package { 'php5-cli': ensure => latest; }

		file { '/var/log/wikistats':
			ensure => directory,
			mode => '0664',
			owner => wikistats,
			group => project-wikistats,
		}

		define wikistats::cronjob() {

			$project = regsubst($name, '@.*', '\1')
			$hour = regsubst($name, '.*@', '\1')

			cron { "cron-wikistats-update-${name}":
				command => "/usr/bin/php /var/lib/wikistats/bin/update.php ${project} > /var/log/wikistats/update_${name}.log 2>&1",
				user => dzahn,
				hour => $hour,
				minute => 0,
				ensure => present,
			}
		}
		# update cron jobs: usage: <project prefix>@<hour>
		wikistats::cronjob { [ 'wp@0','lx@1','wt@2','ws@3','wn@4','wb@5','wq@6','os@7','gt@8','an@9','wf@10','wv@11','sc@12','ne@13','wr@14','et@15','mt@16','un@17','wx@18','mw@19','sw@20','ro@21','re@22','pa@23' ]: }
	}

}
