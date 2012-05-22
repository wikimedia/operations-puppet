# Classes for installing Java JRE and Java JDK from
# various java package providers.


# == Class: java
# Installs jre and/or jdk from a given provider.
#
# To install the OpenJDK JDK, just 'include java'
#
# Note that it is possible to have multiple versions of java
# installed at once.  This class does not ensure that the
# unspecified versions are purged.  Instead, it modifies
# /etc/alternatives (using update-java-alternatives) to set
# the default java binary accordingly.
#
# TODO:  Should this class ensure that the unspecified versions of java are purged?
#
# Since this class makes use of update-alternatives and
# debconf-utils, this class will only work on Debian flavored Linuxes.
#
# Note: I would like to use class inheritence here, but puppet
# does not work well with inheritence and parameterized classes :(
#
# == Parameters
# $provider - either 'sun', 'open', or 'default'.
#   The default-jre/jdk Ubuntu package points at the OpenJDK packges.
#   default: 'default'
#
# $distribution - either 'jdk' or 'jre'.  jdk implies jre.
#   default: 'jdk'
#
# == Examples
#
#   include java    # installs openjdk-6-jdk and openjdk-6-jre
#
#   class { "java": provider => 'sun', distribution => 'jre' }  # installs sun-java6-jre
#
# == Authors
# Andrew Otto <otto@wikimedia.org>
#
class java($provider = 'default', $distribution = 'jdk') {
	# determine the name of the package prefix
	# based on $provider.
	$package_prefix = $provider ? {
		'sun'          => 'sun-java6',  # Sun/Oracle
		'open'         => 'openjdk-6',  # OpenJDK
		default        => 'default',    # Ubuntu/Debian default-jre/jdk.  This currently points at OpenJDK packages.
	}

	# Include either the java::jre class
	# or the java::jdk clas based on $disribution.
	$java_class = "java::${distribution}"
	class { $java_class: package_prefix => $package_prefix }
}


# == Class java::jre
# This class installs a JRE package.  Do not include this class.
# Instead, include java with distribution => 'jre'.
#
# == Parameters
# $package_prefix - either 'sun-java6', 'openjdk-6', or 'default'.
#   default: 'default'
#
class java::jre($package_prefix) {
	# The name of the jre package we want
	# to install based on the prefix
	$jre_package = "${package_prefix}-jre"

	# sun-java requires that we accept
	# Sun/Oracle's license.  If we are using the
	# sun java packages, then do so.
	# (Taken from  http://offbytwo.com/2011/07/20/scripted-installation-java-ubuntu.html
	#  Should this use the generic::debconf::set define from generic-defintions.pp?)
	if $package_prefix == 'sun-java6' {
		exec { "agree-to-jre-license":
			command => "/bin/echo -e sun-java6-jre shared/accepted-sun-dlj-v1-1 select true | debconf-set-selections",
			unless  => "debconf-get-selections | grep 'sun-java6-jre.*shared/accepted-sun-dlj-v1-1.*true'",
			path    => ["/bin", "/usr/bin"],
			before  => Package["java-jre"],
		}
	}

	# Install the JRE package, alias it to
	# 'java-jre' and 'java' so we don't have
	# to care about the real package name later.
	package { $jre_package:
		alias  => ["java-jre", "java"],
		ensure => installed,
	}

	# $java_name is the name of java
	# according to update-alternatives.
	# Both default and openjdk have the same name,
	# since they are the same package.
	$java_name = $package_prefix ? {
		'sun-java6' => 'java-6-sun',
		default     => 'java-6-openjdk',  # default and OpenJDK are the same.
	}

	# set the default java binary to the one asked for here.
	exec { "update-java-alternatives":
		command => "/usr/sbin/update-java-alternatives --set $java_name",
		# No need to run this if the alternative is already set correctly.
		# I could also check the symlink, but this is more robust, even if a bit more hacky.
		unless  => "/usr/sbin/update-alternatives --display java | /bin/grep 'link currently points to' | /bin/grep -q '$java_name'",
		require => Package[$jre_package],
		# For some reason, setting the alternative to sun
		# exists with 2, even though the alternative is updated
		# correctly.  Set 0 and 2 as succesful return values.
		returns => [0,2],
	}
}


# == Class java::jdk
# This class installs a JRE package.  Do not include this class.
# Instead, include java with distribution => 'jdk'.
#
# == Parameters
# $package_prefix - either 'sun-java6', 'openjdk-6', or 'default'.
#   default: 'default'
#
class java::jdk($package_prefix) {
	# include class java::jre.
	class { "java::jre": package_prefix => $package_prefix }

	# The name of the jre package we want
	# to install based on the prefix
	$jdk_package = "${package_prefix}-jdk"
	
	# sun-java requires that we accept
	# Sun/Oracle's license.  If we are using the
	# sun java packages, then do so.
	# (Taken from  http://offbytwo.com/2011/07/20/scripted-installation-java-ubuntu.html
	#  Should this use the generic::debconf::set define from generic-defintions.pp?)
	if $package_prefix == 'sun-java6' {
		exec { "agree-to-jdk-license":
			command => "/bin/echo -e sun-java6-jdk shared/accepted-sun-dlj-v1-1 select true | debconf-set-selections",
			unless  => "debconf-get-selections | grep 'sun-java6-jdk.*shared/accepted-sun-dlj-v1-1.*true'",
			path    => ["/bin", "/usr/bin"],
			before  => Package["java-jdk"],
		}
	}
	
	# Install the JDK package, alias it to
	# 'java-jdk' so we don't have
	# to care about the real package name later.
	package { $jdk_package:
		ensure => installed,
		alias  => "java-jdk",
		require => Package["java-jre"],
	}
}
