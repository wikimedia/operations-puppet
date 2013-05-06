# == Class: bugzilla
#
# This Puppet class provisions Bugzilla, the web-based bug management
# system that powers <https://bugzilla.wikimedia.org/>. It will retrieve
# a Bugzilla release from Bazaar, configure it, and apply Wikimedia
# patches and extensions.
#
# Wikimedia-specific patches are pulled from a Gerrit repository,
# 'wikimedia/bugzilla/modifications'. The patches are synced to the
# Bugzilla checkout and then committed locally.
#
# Note that not all Bugzilla dependencies have been packaged for Debian,
# so some must be fetched from CPAN. Bugzilla's 'install-module.pl' script
# facilitates downloading and installing these modules to a site-specific
# subdirectory ('lib') of the main Bugzilla folder.
#
# === Parameters
#
# [*user*]
#   Owner of Bugzilla files and configuration data (default:
#   'bugzilla'). Will be created if it does not exist.
#
# [*group*]
#   Group for Bugzilla files and configuration data (default:
#   'bugzilla'). Will be created if it does not exist.
#
# [*dir*]
#   Main path for Bugzilla files (default: '/srv/bugzilla'). The actual
#   Bugzilla release will be checked out into a subfolder of this
#   directory. Will be created if it does not exist.
#
# [*release*]
#   A string of three dot-separated numbers specifying the exact
#   Bugzilla release to retrieve and configure (default: '4.2.5').
#
# [*localconfig*]
#   A hash-map of Bugzilla configuration keys and their values. The keys
#   correspond to variables defined in Bugzilla's localconfig.
#
#   This map will be merged onto the default set of values, shown below.
#   The values you should specify are 'urlbase' (the full URL that will
#   server Bugzilla), 'db_host' (the hostname of the MySQL database that
#   will store Bugzilla data), 'db_name' (the logical database name),
#   and the credentials for the database user ('db_user' and 'db_pass').
#
# === Examples
#
#	class { 'bugzilla':
#		release     => '4.2.5',
#		localconfig => {
#			db_host = 'db9.pmtpa.wmnet',
#			db_name = 'bugs',
#			db_user = 'bugs',
#			db_pass = scope.lookupvar('passwords::bugzilla::bugzilla_db_pass'),
#		},
#	}
#
class bugzilla (
	$user        = 'bugzilla',
	$group       = 'bugzilla',
	$dir         = '/srv/bugzilla',
	$release     = '4.2.5',
	$localconfig = {},
) {
	$install_dir = "${dir}/bugzilla-${release}"

	# The version string of a Bugzilla release comprises three
	# dot-separated values ('4.2.5', for example). The release series
	# spans the first two ('4.2').
	$series = regsubst($release,'\.\d+$','')

	$defaults = {
		'ADMIN_EMAIL'     => "admin@${::fqdn}",
		'ADMIN_PASSWORD'  => 'change_me',
		'ADMIN_REALNAME'  => 'Bugzilla Administrator',
		'cvsbin'          => '',
		'db_check'        => 1,
		'db_driver'       => 'mysql',
		'db_host'         => 'localhost',
		'db_name'         => 'bugs',
		'db_pass'         => '',
		'db_port'         => 0,
		'db_sock'         => '',
		'db_user'         => 'bugs',
		'diffpath'        => '/usr/bin',
		'index_html'      => 0,
		'interdiffbin'    => '/usr/bin/interdiff',
		'urlbase'         => "http://${::fqdn}/bugs",
		'use_suexec'      => 0,
		'webservergroup'  => 'www-data',
	    'create_htaccess' => 1,
	}

	if ! defined(Group[$group]) {
		group { $group:
			ensure => present,
		}
	}

	if ! defined(User[$user]) {
		user { $user:
			ensure     => present,
			gid        => $group,
			shell      => '/bin/false',
			home       => $dir,
			managehome => true,
			system     => true,
		}
	}

	if ! defined(File[$dir]) {
		file { $dir:
			ensure => directory,
			owner  => $user,
			group  => $group,
			mode   => '0755',
		}
	}

	package { 'bzr': ensure => present, }

	exec { 'bzr checkout':
		command => "bzr co -r tag:bugzilla-${release} bzr://bzr.mozilla.org/bugzilla/${series} ${install_dir}",
		creates => "${install_dir}/.bzr/branch-format",
		require => Package['bzr'],
		path    => '/usr/bin',
		user    => $user,
	}


	$dependencies = [
		'libapache2-mod-perl2',
		'libapache2-mod-perl2-dev',
		'libauthen-sasl-perl',
		'libauthen-simple-ldap-perl',
		'libauthen-simple-radius-perl',
		'libcgi-pm-perl',
		'libchart-perl',
		'libdatetime-perl',
		'libdatetime-timezone-perl',
		'libdbd-mysql-perl',
		'libdbi-perl',
		'libdigest-sha-perl',
		'libemail-mime-perl',
		'libemail-send-perl',
		'libencode-detect-perl',
		'libgd-gd2-perl',
		'libgd-graph-perl',
		'libgd-text-perl',
		'libhtml-parser-perl',
		'libhtml-scrubber-perl',
		'libjson-rpc-perl',
		'liblwp-useragent-determined-perl',
		'libmath-random-isaac-perl',
		'libmime-tools-perl',
		'libsoap-lite-perl',
		'libtemplate-perl',
		'libtemplate-plugin-gd-perl',
		'libtest-taint-perl',
		'libtheschwartz-perl',
		'libtimedate-perl',
		'liburi-perl',
		'libxml-twig-perl',
		'libyaml-perl',
	]

	package { $dependencies:
		ensure => present,
	}

	# Enabling Apache's mod_headers and mod_expires makes it possible to
	# upgrade Bugzilla without requiring that all users clear their
	# browser cache.
	apache::mod { [ 'headers', 'expires' ]: }

	# These Perl modules have not been packaged for Debian. They'll be
	# pulled from CPAN by Bugzilla's install-module.pl and installed to
	# Bugzilla's 'lib' subdirectory.
	$extra_modules = [
		'Apache2::SizeLimit',
		'Email::MIME::Attachment::Stripper',
		'Email::Reply',
		'PatchReader',
		'Daemon::Generic',  # Bugzilla doesn't like 'libdaemon-generic-perl' in apt.
		'Search::Sitemap',
	]

	exec { 'extra modules':
		command => shellquote('perl', 'install-module.pl', $extra_modules),
		onlyif  => 'perl checksetup.pl --check-modules 2>&1 | grep -q install-module',
		cwd     => $install_dir,
		path    => [ '/bin', '/usr/bin' ],
		require => [ Package[$dependencies], Exec['bzr checkout'] ],
		user    => $user,
	}

	# Generate an answer file for an unattended setup. See 'perldoc
	# checksetup.pl' for details.
	file { 'answer file':
		path    => "${dir}/answerfile.pl",
		content => template('bugzilla/answerfile.pl.erb'),
		require => File[$dir],
		notify  => Exec['check setup'],
	}

	# checksetup.pl needs to run twice: once to generate the
	# configuration file, and a second time to act on it.
	exec { 'check setup':
		command     => "perl checksetup.pl ${dir}/answerfile.pl && test -d data",
		cwd         => $install_dir,
		tries       => 2,
		path        => '/usr/bin',
		refreshonly => true,
		require     => Exec['extra modules'],
		user        => $user,
	}

	git::clone { 'wikimedia/bugzilla/modifications':
		ensure    => present,
		directory => "${dir}/modifications",
		origin    => 'https://gerrit.wikimedia.org/r/p/wikimedia/bugzilla/modifications.git',
		branch    => 'master',
	}

	# Copy Wikimedia-specific modifications to the Bugzilla tree.
	exec { 'apply modifications':
		command     => "rsync -r ${dir}/modifications/bugzilla-${series}/ ${install_dir}",
		creates     => "${install_dir}/extensions/Wikimedia/",
		notify      => Exec['commit modifications'],
		path        => '/usr/bin',
		refreshonly => true,
		require     => Exec['bzr checkout'],
	}

	# Create a local Bazaar commit of Wikimedia modifications and label
	# it with the SHA1 of wikimedia/bugzilla/modifications's tip.
	$ref = "${dir}/modifications/.git/refs/heads/master"
	exec { 'commit modifications':
		command     => "bzr add && bzr commit --local --file=${ref}",
		unless      => "bzr log -l1 | grep -f ${ref}",
		cwd         => $install_dir,
		path        => [ '/bin', '/usr/bin' ],
		refreshonly => true,
	}
}
