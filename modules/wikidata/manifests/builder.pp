# == Class: wikidata::builder

class wikidata::builder {

	package { [
		'nodejs',
		'npm',
		'php5',
		'git',
		]:
		ensure => 'present';
	}
	package { 'grunt-cli':
		ensure		=> 'present',
		provider	=> 'npm',
		require		=> Package['nodejs'],
	}

	file { '/home/wdbuilder':
		ensure	=> 'directory',
		owner	=> 'wdbuilder',
		group	=> 'wdbuilder',
		mode	=> '0700',
		require	=> [ User['wdbuilder'], Group['wdbuilder'] ],
	}

	group { 'wdbuilder':
		ensure	=> present,
	}

	user { 'wdbuilder':
		ensure		=> 'present',
		home		=> '/home/wdbuilder',
		name		=> 'wdbuilder',
		shell		=> '/bin/bash',
		managehome	=> true,
	}

	git::clone { 'clone_wikidatabuilder':
		directory	=> '/home/wdbuilder/buildscript',
		# TODO move repo to wmde github group
		origin		=> 'https://github.com/JeroenDeDauw/WikidataBuilder.git',
		ensure		=> 'latest',
		owner		=> 'wdbuilder',
		group		=> 'wdbuilder',
		before  => Exec['npm_install']
	}

	git::clone { 'clone_wikidata':
		directory	=> '/home/wdbuilder/wikidata',
		# TODO use a different repo once deploying!
		origin		=> 'https://github.com/addshore/WikidataBuild.git',
		ensure		=> 'latest',
		owner		=> 'wdbuilder',
		group		=> 'wdbuilder',
	}

	exec { 'npm_install':
		user	=> 'wdbuilder',
		command	=> 'cd /home/wdbuilder/buildscript && npm install',
	}

# TODO uncomment when ready
#	cron { 'builder_cron':
#		ensure	=> present,
#		# TODO commit the build to another repo
#		command	=> 'cd /home/wdbuilder/buildscript && grunt build:Wikidata_master',
#		user	=> 'wdbuilder',
#		hour	=> '*/1',
#		minute	=> [ 0, 30 ],
#	}

}