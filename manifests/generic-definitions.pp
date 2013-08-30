# generic-definitions.pp
#
# File that contains generally useful definitions, e.g. for creating system users

# Prints a MOTD message about the role of this system
define system_role($description, $ensure=present) {
	$role_script_content = "#!/bin/sh

echo \"$(hostname) is a Wikimedia ${description} (${title}).\"
"

	$rolename = regsubst($title, ":", "-", "G")
	$motd_filename = "/etc/update-motd.d/05-role-${rolename}"

	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "9.10") >= 0 {
		file { $motd_filename:
			owner => root,
			group => root,
			mode => 0555,
			content => $role_script_content,
			ensure => $ensure;
		}
	}
}

# Creates a system username with associated group, random uid/gid, and /bin/false as shell
define systemuser($name, $home=undef, $managehome=true, $shell="/bin/false", $groups=undef, $default_group=$name, $ensure=present) {
	# FIXME: deprecate $name parameter in favor of just using $title

	if $default_group == $name {
		group { $default_group:
			name => $default_group,
			ensure => present;
		}
	}

	user { $name:
		require => Group[$default_group],
		name => $name,
		gid => $default_group,
		home => $home ? {
			undef => "/var/lib/${name}",
			default => $home
		},
		managehome => $managehome,
		shell => $shell,
		groups => $groups,
		system => true,
		ensure => $ensure;
	}
}

# Enables a certain Apache 2 site
define apache_site($name, $prefix="", $ensure="link") {
	file { "/etc/apache2/sites-enabled/${prefix}${name}":
		target => "/etc/apache2/sites-available/$name",
		ensure => $ensure;
	}
}

# Enables a certain Apache 2 module
define apache_module($name) {
	file {
		"/etc/apache2/mods-available/${name}.conf":
			ensure => present;
		"/etc/apache2/mods-available/${name}.load":
			ensure => present;
		"/etc/apache2/mods-enabled/${name}.conf":
			ensure => "../mods-available/${name}.conf";
		"/etc/apache2/mods-enabled/${name}.load":
			ensure => "../mods-available/${name}.load";
	}
}

define apache_confd($install="false", $enable="true", $ensure="present") {
	case $install {
		"true": {
			file { "/etc/apache2/conf.d/${name}":
				source => "puppet:///files/apache/conf.d/${name}",
				mode => 0444,
				ensure => $ensure;
			}
		}
		"template": {
			file { "/etc/apache2/conf.d/${name}":
				content => template("apache/conf.d/${name}.erb"),
				mode => 0444,
				ensure => $ensure;
			}
		}
	}
}


# Enables a certain Lighttpd config
#
# TODO:  ensure => false removes symlink.  ensure => purged removes available file.
define lighttpd_config($install="false") {
	# Reload lighttpd if the site config file changes.
	# This subscribes to both the real file and the symlink.
	exec { "lighttpd_reload_${title}":
		command     => "/usr/sbin/service service lighttpd reload",
		refreshonly => true,
	}

	if $install == "true" {
		file { "/etc/lighttpd/conf-available/${title}.conf":
			source => "puppet:///files/lighttpd/${title}.conf",
			owner => root,
			group => www-data,
			mode => 0444,
			before => File["/etc/lighttpd/conf-enabled/${title}.conf"],
			notify => Exec["lighttpd_reload_${title}"],
		}
	}

	# Create a symlink to the available config file
	# in the conf-enabled directory.  Notify
	file { "/etc/lighttpd/conf-enabled/${title}.conf":
		ensure => "/etc/lighttpd/conf-available/${title}.conf",
		notify => Exec["lighttpd_reload_${title}"],
	}

}

# Enables a certain NGINX site
define nginx_site($install=false, $template="", $enable=true) {
	if ( $template == "" ) {
		$template_name = $name
	} else {
		$template_name = $template
	}
	if ( $enable == true ) {
		file { "/etc/nginx/sites-enabled/${name}":
			ensure => "/etc/nginx/sites-available/${name}",
		}
	} else {
		file { "/etc/nginx/sites-enabled/${name}":
			ensure => absent;
		}
	}

	case $install {
	true: {
			file { "/etc/nginx/sites-available/${name}":
				source => "puppet:///files/nginx/sites/${name}";
			}
		}
	"template": {
			file { "/etc/nginx/sites-available/${name}":
				content => template("nginx/sites/${template_name}.erb");
			}
		}
	}
}

# Create a symlink in /etc/init.d/ to a generic upstart init script

define upstart_job($install="false", $start="false") {
	# Create symlink
	file { "/etc/init.d/${title}":
		ensure => "/lib/init/upstart-job";
	}

	if $install == "true" {
		file { "/etc/init/${title}.conf":
			source => "puppet:///files/upstart/${title}.conf"
		}
	}

	if $start == "true" {
		exec { "start $title":
			require => File["/etc/init/${title}.conf"],
			subscribe => File["/etc/init/${title}.conf"],
			refreshonly => true,
			command => "start ${title}",
			path => "/bin:/sbin:/usr/bin:/usr/sbin"
		}
	}
}

class base::mwclient {
    package { python-mwclient: ensure => latest; }
}

class generic::gluster-client {

	package { "glusterfs-client":
		ensure => present;
	}

    file { [ '/var/log/glusterfs', '/var/log/glusterfs/bricks' ]:
        ensure => directory,
        before => File['/etc/logrotate.d/glusterlogs'],
    }

	file { "/etc/logrotate.d/glusterlogs":
		ensure => present,
		mode => '0664',
		source => "puppet:///files/logrotate/glusterlogs",
		owner => 'root',
	}

	# Gluster installs this but it doesn't work and breaks
	# the behavior of /etc/logrotate.d/glusterlogs.
	file { "/etc/logrotate.d/glusterfs-common":
		ensure => absent,
	}
}

class generic::gluster-server {

	package { "glusterfs-server":
		ensure => present;
	}

}

# The joe editor, which has some fans among labs users
class generic::packages::joe {
	package { "joe" : ensure => latest; }
}

# An utility to show up a file hierarcy using ASCII art
class generic::packages::tree {
	package { "tree" : ensure => present; }
}

# Definition: git::clone
#
# Creates a git clone of a specified origin into a top level directory.
#
# === Required parameters
#
# $+directory+:: path to clone the repository into.
# $+origin+:: Origin repository URL.
#
# === Optional parameters
#
# $+branch+:: Branch you would like to check out.
# $+ensure+:: _absent_, _present_, or _latest_.  Defaults to _present_.
#             - _present_ (default) will just clone once.
#             - _latest_ will execute a git pull if there are any changes.
#             - _absent_ will ensure the directory is deleted.
# $+owner+:: Owner of $directory, default: _root_.  git commands will be run by this user.
# $+group+:: Group owner of $directory, default: 'root'
# $+mode+:: Permission mode of $directory, default: 0755
# $+ssh+:: SSH command/wrapper to use when checking out, default: ''
# $+timeout+:: Time out in seconds for the exec command, default: 300
#
# === Example usage
#
#	git::clone{ "my_clone_name":
#		directory => "/path/to/clone/container",
#		origin    => "http://blabla.org/core.git",
#		branch    => "the_best_branch"
#	}
#
# Will clone +http://blabla.org/core.git+ branch +the_best_branch+ at +/path/to/clone/container/core+
define git::clone(
	$directory,
	$origin,
	$branch="",
	$ssh="",
	$ensure='present',
	$owner="root",
	$group="root",
	$timeout="300",
	$depth="full",
	$mode=0755) {

	case $ensure {
		"absent": {
			# make sure $directory does not exist
			file { $directory:
				ensure  => 'absent',
				recurse => true,
				force   => true,
			}
		}

		# otherwise clone the repository
		default: {
			# if branch was specified
			if $branch {
				$brancharg = "-b $branch "
			}
			# else don't checkout a non-default branch
			else {
				$brancharg = ""
			}
			if $ssh {
				$env = "GIT_SSH=$ssh"
			}

			$deptharg = $depth ?  {
				"full" => "",
				default => " --depth=$depth"
			}

			# set PATH for following execs
			Exec { path => "/usr/bin:/bin" }
			# clone the repository
			exec { "git_clone_${title}":
				command     => "git clone ${brancharg}${origin}${deptharg} $directory",
				logoutput   => on_failure,
				cwd         => '/tmp',
				environment => $env,
				creates     => "$directory/.git/config",
				user        => $owner,
				group       => $group,
				timeout     => $timeout,
				require     => Package["git-core"],
			}

			# pull if $ensure == latest and if there are changes to merge in.
			if $ensure == "latest" {
				exec { "git_pull_${title}":
					cwd     => $directory,
					command => "git pull --quiet${deptharg}",
					logoutput => on_failure,
					# git diff --quiet will exit 1 (return false) if there are differences
					unless  => "git fetch && git diff --quiet remotes/origin/HEAD",
					user    => $owner,
					group   => $group,
					require => Exec["git_clone_${title}"],
				}
			}
		}
	}
}


define git::init($directory) {
	$suffix = regsubst($title, '^([^/]+\/)*([^/]+)$', '\2')

	exec {
		"git init ${title}":
			path => "/usr/bin:/bin",
			command => "git init",
			cwd => "${directory}/${suffix}",
			creates => "${directory}/${suffix}/.git/config",
			require => Package["git-core"];
	}
}


# Creating an apparmor service class
# so we can notify the service when
# apparmor files are changed by puppet.
# This probably isn't included in your
# class, so if you need to notify this
# service make sure you include it.
class generic::apparmor::service {
	service { "apparmor":
		ensure => 'running',
	}
}

# handle locales via puppet
class generic::packages::locales {
	package { "locales": ensure => latest; }
}

class generic::packages::ant18 {

  if ($::lsbdistcodename == "lucid") {
		# When specifying 'latest' for package 'ant' on Lucid it will actually
		# install ant1.7 which might not be the version we want. This is similar to
		# the various gcc version packaged in Debian, albeit ant1.7 and ant1.8 are
		# conflicting with each others.
		# Thus, this let us explicitly install ant version 1.8
		package { [
			"ant1.8"
		]: ensure => installed;
		}
		package { [
			"ant",
			"ant1.7"
		]: ensure => absent;
		}
	} else {
		# Ubuntu post Lucid ship by default with ant 1.8 or later
		package { ["ant"]: ensure => installed; }
	}
}

class generic::packages::maven {
	# Install Apache Maven, a java build processing tool.
	# Class can later be used to add additional Maven plugins
	# http://maven.apache.org/
	package { [
		"maven2"
	]: ensure => latest;
	}
}

class generic::sysfs::enable-rps {
	upstart_job { "enable-rps": install => "true", start => "true" }
}

# this installs a bunch of international locales, f.e. for "planet" on singer
class generic::locales::international {

	require generic::packages::locales

	file { "/var/lib/locales/supported.d/local":
		source => "puppet:///files/locales/local_int",
		owner => "root",
		group => "root",
		mode => 0444;
	}

	exec { "/usr/sbin/locale-gen":
		subscribe => File["/var/lib/locales/supported.d/local"],
		refreshonly => true,
		require => File["/var/lib/locales/supported.d/local"];
	}
}

# Definition: generic::debconf::set
# Changes a debconf value
#
# Parameters:
# - $title
#		Debconf setting, e.g. mailman/used_languages
# - $value
#		The value $title should be set to
define generic::debconf::set($value) {
	exec { "debconf-communicate set $title":
		path => "/usr/bin:/usr/sbin:/bin:/sbin",
		command => "echo set ${title} \"${value}\" | debconf-communicate",
		unless => "test \"$(echo get ${title} | debconf-communicate)\" = \"0 ${value}\""
	}
}

# python pip and virtualenv.
# only use this on development systems.
# in order to go to production, all dependencies need to come from debian packages, not pip.
class generic::pythonpip {
	package { [ "python-pip", "python-dev", "build-essential" ]:
		ensure => latest;
	}

	# pip could be in /usr/bin/ or in /usr/local/bin
	exec { "update_pip":
			command => "pip install --upgrade pip",
			path    => ["/usr/bin", "/usr/local/bin"],
			require => Package["python-pip"];
		"update_virtualenv":
			command => "pip install --upgrade virtualenv",
			path    => ["/usr/bin", "/usr/local/bin"],
			require => Package["python-pip"];
	}
}


class generic::wikidev-umask {

	# set umask to 0002 for wikidev users, per RT-804
	file {
		"/etc/profile.d/umask-wikidev.sh":
			ensure => present,
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/environment/umask-wikidev-profile-d.sh";
	}
	# if lucid or earlier /etc/profile would overwrite umask after incl. above
	# FIXME: remove this once fenari became precise or there is a new deploy host
	if versioncmp($::lsbdistrelease, "10.04") <= 0 {
		file {
				"/etc/profile":
				ensure => present,
				owner => root,
				group => root,
				source => "puppet:///files/environment/profile-deploy-host";
		}
	}
}


class generic::higher_min_free_kbytes {
	# Set a high min_free_kbytes watermark.
	# See https://wikitech.wikimedia.org/wiki/Dataset1001#Feb_8_2012
	# FIXME: Is this setting appropriate to the nodes on which it is applied? Is
	# the value optimal? Investigate.
	sysctl::parameters { 'higher_min_free_kbytes':
		values => {
			'vm.min_free_kbytes' => 1024 * 256,
		},
	}
}
