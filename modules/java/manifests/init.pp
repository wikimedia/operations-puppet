# == Define: java
# Installs a given distribution and version of java,
# and updates alternatives to the given version.
#
# Note that this is not a class so that it is possible
# to install multiple versions of Java at once.  The
# default Java version will be selected using
# update-alternatives.  You may specify which installed
# version is the default by setting alternative => true.
#
#
# == Parameters
#
# $title - This is arbitrary.  It will only be used
#   for aliasing the installed packages.
#
# $distribution - 'openjdk', 'sun' or 'oracle'.  'sun' and 'oracle' are equivalent.
#   default: 'openjdk'
#
# $jdk - If false, $jdk will not be installed.
#   default: true
#
# $version - Java version to install.
#   default: 6 for Oracle or for openjdk on Lucid, 7 for openjdk on Precise.
#
# $ensure - This will be passed to package resource.
#   You should only set this if you want to uninstall java.
#   default: 'installed'
#
# $alternative - If true, then update-alternatives will
#   set this version of java as the default.  You
#   may only define a single Java version as the default
#   alternative.  Leaving alternative => true on more than one
#   install version of Java will make puppet throw an error.
#
# == Examples
#
# # Install the default (openjdk) Java version.
# # On Lucid this will be openjdk-6, on Precise openjdk-7
# java { 'java-6-default': }
#
# # Install openjdk-6 (non default) on Precise.
# java { 'java-6-precise': version => 6 }
#
# # Install sun|oracle Java 6 on Lucid.  (sun-java6)
# # (Sun|Oracle Java 7 is not currently available)
# java { 'java-sun-lucid': distribution => 'sun' }
#
# # Install sun|oracle Java 6 on Precise.  (oracle-j2sdk1.6)
# # Note that 'sun' and 'oracle' distributions are
# # equivalent to this define.
# java { 'java-oracle-precise': distribution => 'oracle }
#
# # Uninstall sun|oracle Java on Precise.
# java { 'java-oracle-precise': distribution => 'oracle', ensure => 'absent' }
#
# # Install openjdk-6 without JDK.
# java { 'java-6-no-jdk': jdk => false, version => 6 }
#
# # Install openjdk-6, openjdk-7, and sun|oracle Java 6 on Precise,
# # choosing sun|oracle Java 6 as the default alternative.
# java { 'java-6-oracle':  distribution => 'oracle', version => 6, alternative => true }
# java { 'java-6-openjdk': distribution => 'openjdk' version => 6, alternative => false }
# java { 'java-7-openjdk': distribution => 'openjdk' version => 7, alternative => false }
#
# == Notes
# I wish the conditionals in this define didn't look so complicated!
# Here's a table of all the available java package names for
# Ubuntu Lucid and Precise.
#
#      OS  Distribution     JRE/JDK  Version        PackageName
# *             openjdk         JRE        6        openjdk-6-jre
# *             openjdk         JDK        6        openjdk-6-jdk
#   lucid    sun|oracle         JRE        6        sun-java6-jre
#   lucid    sun|oracle         JDK        6        sun-java6-jdk
# precise    sun|oracle         JDK        6        oracle-j2sdk1.6
# precise       openjdk         JRE        7        openjdk-7-jre
# precise       openjdk         JDK        7        openjdk-7-jdk
#
# You can see how it could get complicated.  I want to abstract out
# this complexity so that the user of this define doesn't have to think
# about this.  They should be able to specify the distribution
# and version of java that they want, and not worry about the name
# of the package, having to agree to Oracle licenses, or to update
# java alternatives.
#
# == Authors
# Andrew Otto <otto@wikimedia.org>
#
define java($distribution = 'openjdk', $jdk = true, $version = 'default', $ensure = 'installed', $alternative = true) {

	# Below is a set of conditionals that set $package_prefix
	# based on $distribution, $version, and $::lsbdistrelease.

	# TODO:  What is the proper $::lsbdistrelease?
	# I am using 11.10.  Is this correct?  It will
	# work for our main differentiation: Lucid vs. Precise.
	# The proper thing to do would be to inspect the default-jre
	# and default-jdk package aliases provided by Ubuntu, and use
	# that to determine the proper default.

	# Choose 'openjdk' distribution as the default
	if ($distribution == 'openjdk') {
		# if version is default, choose the default version
		# for the current version of Ubuntu.
		if ($version == 'default') {
			# use openjdk-7 as default for newer Ubuntus
			if (versioncmp($::lsbdistrelease, "11.10") >= 0) {
				$package_prefix = 'openjdk-7'
			}
			# else use openjdk-6
			else {
				$package_prefix = 'openjdk-6'
			}
		}
		# else use the version specified.
		else {
			$package_prefix = "openjdk-${version}"
		}
	}
	# if we want Sun/Oracle java
	elsif ($distribution == 'sun' or $distribution == 'oracle') {
		# if we're on a newer Ubuntu version
		if (versioncmp($::lsbdistrelease, "11.10") >= 0) {
			# if version was not specified,
			# use 6 (Oracle Java 7 is not available)
			if ($version == 'default') {
				$java_version = '6'
			}
			else {
				$java_version = $version
			}

			# fail if we want version 7
			if ($java_version != '6') {
				fail("Oracle/Sun Java Version $java_version packages are not available for Ubuntu $::lsbdistrelease")
			}

			$package_prefix = 'oracle-j2sdk1.6'
		}
		# otherwise use sun-java6
		else {
			$package_prefix = 'sun-java6'
		}
	}
	# else fail.
	else {
		fail("Bad combination of distribution '$distribution' and version '$version' when installing java packages on Ubuntu $::lsbdistrelease")
	}


	# We will only run update-alternatives
	# and alias installed packages to global java names
	# (java, java-jre, java-jdk) if we want to set this
	# as the java alternative AND we want this java version
	# installed.
	$choose_alternative = ($alternative and $ensure == 'installed')



	#
	# Install JRE
	#

	# The later Ubuntu Java 6 Oracle package does not have a 'JRE' package,
	# so skil all the steps here to install JRE.  Later,
	# the Oracle package will be aliased to java and java-jre
	if ($package_prefix != 'oracle-j2sdk1.6') {
		# sun-java requires that we accept
		# Sun/Oracle's license.  If we are using the
		# sun java packages, then do so.
		# (Taken from  http://offbytwo.com/2011/07/20/scripted-installation-java-ubuntu.html
		#  Should this use the generic::debconf::set define from generic-defintions.pp?)
		if ($package_prefix == 'sun-java6') {
			exec { "agree-to-jre-license":
				command => "/bin/echo -e sun-java6-jre shared/accepted-sun-dlj-v1-1 select true | debconf-set-selections",
				unless  => "debconf-get-selections | grep 'sun-java6-jre.*shared/accepted-sun-dlj-v1-1.*true'",
				path    => ["/bin", "/usr/bin"],
				before  => Package["java-jre"],
			}
		}

		# $alternative should only be set to true
		# for a single java version installation.
		# Alias this $jre-package to handy names
		$jre_alias = $choose_alternative ? {
			true    => ['java', 'java-jre', "${title}", "${title}-jre"],
			default => ["${title}", "${title}-jre"],
		}

		$jre_package = "${package_prefix}-jre"
		package { "$jre_package":
			ensure => $ensure,
			alias  => $jre_alias,
		}


		# openjdk package installs a few other dependencies.
		# these don't seem to get uninstalled when ensure == 'absent',
		# so we'll manually manage them here.
		if ($distribution == 'openjdk') {
			package { ["${package_prefix}-jre-lib", "${package_prefix}-jre-headless"]:
				ensure => $ensure,
			}
		}
	}

	#
	# Install JDK
	#

	# Install JDK if jdk argument is true, or if
	# we need to install oracle-j2sdk1.6.
	# (The oracle-j2sdk1.6 package does not differentiate
	# between JRE and JDK).
	if ($jdk or $package_prefix == 'oracle-j2sdk1.6') {
		# sun-java requires that we accept
		# Sun/Oracle's license.  If we are using the
		# sun java packages, then do so.
		# (Taken from  http://offbytwo.com/2011/07/20/scripted-installation-java-ubuntu.html
		#  Should this use the generic::debconf::set define from generic-defintions.pp?)
		# Note that this only needs to be done for sun-java6 packages,
		# i.e. Sun/Oracle java installed on older (Lucid, etc.) Ubuntus.
		if ($package_prefix == 'sun-java6') {
			exec { "agree-to-jdk-license":
				command => "/bin/echo -e sun-java6-jdk shared/accepted-sun-dlj-v1-1 select true | debconf-set-selections",
				unless  => "debconf-get-selections | grep 'sun-java6-jdk.*shared/accepted-sun-dlj-v1-1.*true'",
				path    => ["/bin", "/usr/bin"],
				before  => Package["java-jdk"],
			}
		}

		# The only thing to install for oracle on later Ubuntu
		# is JDK, so use the original package_prefix as the jdk_package.
		$jdk_package = $package_prefix ? {
			'oracle-j2sdk1.6' => 'oracle-j2sdk1.6',
			default           => "${package_prefix}-jdk",
		}


		# if we passed a non-default ensure argument
 		# then use that as the argument
		# to the package's ensure.
		if ($ensure != 'installed')  {
			$jdk_ensure = $ensure
		}
		# else we need to check to see for a special
		# case for oracle-j2sdk1.6.
		else {
			# oracle-j2sdk1.6 will not install
			# unless we pass --force-yes.
			# Puppet will pass this only if
			# ensure is set to a specific version.
			$jdk_ensure = $package_prefix ? {
				'oracle-j2sdk1.6' => '1.6.0+update32',
				default           => 'installed'
			}
		}

		# $alternative should only be set to true
		# for a single java version installation.
		# Alias this $jdk_package to handy names
		$jdk_alias = $package_prefix ? {
			# since JRE does not exist for oracle java 1.6,
			# go ahead and alias this package to $name-jre' and $name as well as jdk.
			'oracle-j2sdk1.6' => $choose_alternative ? {
				true     => ['java-jdk', 'java-jre', 'java', "${title}-jdk", "${title}-jre", "${title}"],
				default  => ["${title}-jdk", "${title}-jre", "${title}"],
			},
			# else just use java-jdk
			default => $choose_alternative ? {
				true     => ["java-jdk", "${title}-jdk"],
				default  => ["${title}-jdk"],
			}
		}


		# Install the JDK package, alias it to
		# 'java-jdk' so we don't have
		# to care about the real package name later.
		package { $jdk_package:
			ensure => $jdk_ensure,
			alias  => $jdk_alias,
		}

		# as long as we aren't installing Oracle JDK on newer Ubuntu,
		# then require JRE.  (There is no Oracle JRE package available on
		# newer Ubuntu).
		if ($package_prefix != 'oracle-j2sdk1.6') {
			Package[$jdk_package] { require +> Package["${title}-jre"] }
		}
	}

	# only need to update alternatives if
	# we are ensuring that Java is installed.
	if ($choose_alternative) {
		#
		# update-alternatives for our installed version of java.
		#

		# $java_name is the name of java
		# according to update-alternatives.
		#
		# Note: None of these names match the packages, sigh.
		$temp_java_name = $package_prefix ? {
			'sun-java6'       => 'java-6-sun',
			'openjdk-6'       => 'java-1.6.0-openjdk',
			'openjdk-7'       => 'java-1.7.0-openjdk',
			'oracle-j2sdk1.6' => 'j2sdk1.6-oracle',
			default           => false,
		}

		# fail if we didnt' get a good java name
		if (!$temp_java_name) {
			fail("Error attempting to find java name for update-alternatives.  Package prefix is $package_prefix.")
		}

		# Newer Ubuntu's append the arch to $java_name
		# for openjdk.
		if ($package_prefix =~ /openjdk/ and versioncmp($::lsbdistrelease, "11.10") >= 0) {
			$java_name = "${temp_java_name}-$::architecture"
		}
		# else just use the $temp_java_name we already picked.
		else {
			$java_name = $temp_java_name
		}

		# set the default java binary to the one asked for here.
		exec { "update-java-alternatives":
			command => "/usr/sbin/update-java-alternatives --set $java_name",
			# No need to run this if the alternative is already set correctly.
			# I could also check the symlink, but this is more robust, even if a bit more hacky.
			unless  => "/usr/sbin/update-alternatives --display java | /bin/grep 'link currently points to' | /bin/grep -q '$java_name'",
			require => Package["${title}-jre"],
			# For some reason, setting the alternative to sun
			# exits with 2, even though the alternative is updated
			# correctly.  Set 0 and 2 as succesful return values.
			returns => [0,2],
		}
	}
}















#
# Below are my previous classes for installing Java.
# These classes did not take into account the different
# package names on Precise.  I am leaving them here
# commented out for posterity.  They are much nicer
# and more organized than the above java class, but
# that is due to the less complex package names.
#







# # Classes for installing Java JRE and Java JDK from
# # various java package providers.
#
#
# # == Class: java
# # Installs jre and/or jdk from a given provider.
# #
# # To install the OpenJDK JDK, just 'include java'
# #
# # Note that it is possible to have multiple versions of java
# # installed at once.  This class does not ensure that the
# # unspecified versions are purged.  Instead, it modifies
# # /etc/alternatives (using update-java-alternatives) to set
# # the default java binary accordingly.
# #
# # TODO:  Should this class ensure that the unspecified versions of java are purged?
# #
# # Since this class makes use of update-alternatives and
# # debconf-utils, this class will only work on Debian flavored Linuxes.
# #
# # Note: I would like to use class inheritence here, but puppet
# # does not work well with inheritence and parameterized classes :(
# #
# # == Parameters
# # $provider - either 'sun', 'open', or 'default'.
# #   The default-jre/jdk Ubuntu package points at the OpenJDK packges.
# #   default: 'default'
# #
# # $distribution - either 'jdk' or 'jre'.  jdk implies jre.
# #   default: 'jdk'
# #
# # == Examples
# #
# #   include java    # installs openjdk-6-jdk and openjdk-6-jre
# #
# #   class { "java": provider => 'sun', distribution => 'jre' }  # installs sun-java6-jre
# #
# # == Authors
# # Andrew Otto <otto@wikimedia.org>
# #
# class java($provider = 'default', $distribution = 'jdk') {
# 	# determine the name of the package prefix
# 	# based on $provider.
# 	$package_prefix = $provider ? {
# 		'sun'          => 'sun-java6',  # Sun/Oracle
# 		'open'         => 'openjdk-6',  # OpenJDK
# 		default        => 'default',    # Ubuntu/Debian default-jre/jdk.  This currently points at OpenJDK packages.
# 	}
#
# 	# Include either the java::jre class
# 	# or the java::jdk clas based on $disribution.
# 	$java_class = "java::${distribution}"
# 	class { $java_class: package_prefix => $package_prefix }
# }
#
#
# # == Class java::jre
# # This class installs a JRE package.  Do not include this class.
# # Instead, include java with distribution => 'jre'.
# #
# # == Parameters
# # $package_prefix - either 'sun-java6', 'openjdk-6', or 'default'.
# #
# class java::jre($package_prefix) {
# 	# The name of the jre package we want
# 	# to install based on the prefix
# 	$jre_package = "${package_prefix}-jre"
#
# 	# sun-java requires that we accept
# 	# Sun/Oracle's license.  If we are using the
# 	# sun java packages, then do so.
# 	# (Taken from  http://offbytwo.com/2011/07/20/scripted-installation-java-ubuntu.html
# 	#  Should this use the generic::debconf::set define from generic-defintions.pp?)
# 	if $package_prefix == 'sun-java6' {
# 		exec { "agree-to-jre-license":
# 			command => "/bin/echo -e sun-java6-jre shared/accepted-sun-dlj-v1-1 select true | debconf-set-selections",
# 			unless  => "debconf-get-selections | grep 'sun-java6-jre.*shared/accepted-sun-dlj-v1-1.*true'",
# 			path    => ["/bin", "/usr/bin"],
# 			before  => Package["java-jre"],
# 		}
# 	}
#
# 	# Install the JRE package, alias it to
# 	# 'java-jre' and 'java' so we don't have
# 	# to care about the real package name later.
# 	package { $jre_package:
# 		alias  => ["java-jre", "java"],
# 		ensure => installed,
# 	}
#
# 	# $java_name is the name of java
# 	# according to update-alternatives.
# 	# Both default and openjdk have the same name,
# 	# since they are the same package.
# 	$java_name = $package_prefix ? {
# 		'sun-java6' => 'java-6-sun',
# 		default     => 'java-6-openjdk',  # default and OpenJDK are the same.
# 	}
#
# 	# set the default java binary to the one asked for here.
# 	exec { "update-java-alternatives":
# 		command => "/usr/sbin/update-java-alternatives --set $java_name",
# 		# No need to run this if the alternative is already set correctly.
# 		# I could also check the symlink, but this is more robust, even if a bit more hacky.
# 		unless  => "/usr/sbin/update-alternatives --display java | /bin/grep 'link currently points to' | /bin/grep -q '$java_name'",
# 		require => Package[$jre_package],
# 		# For some reason, setting the alternative to sun
# 		# exists with 2, even though the alternative is updated
# 		# correctly.  Set 0 and 2 as succesful return values.
# 		returns => [0,2],
# 	}
# }
#
#
# # == Class java::jdk
# # This class installs a JRE package.  Do not include this class.
# # Instead, include java with distribution => 'jdk'.
# #
# # == Parameters
# # $package_prefix - either 'sun-java6', 'openjdk-6', or 'default'.
# #
# class java::jdk($package_prefix) {
# 	# include class java::jre.
# 	class { "java::jre": package_prefix => $package_prefix }
#
# 	# The name of the jre package we want
# 	# to install based on the prefix
# 	$jdk_package = "${package_prefix}-jdk"
#
# 	# sun-java requires that we accept
# 	# Sun/Oracle's license.  If we are using the
# 	# sun java packages, then do so.
# 	# (Taken from  http://offbytwo.com/2011/07/20/scripted-installation-java-ubuntu.html
# 	#  Should this use the generic::debconf::set define from generic-defintions.pp?)
# 	if $package_prefix == 'sun-java6' {
# 		exec { "agree-to-jdk-license":
# 			command => "/bin/echo -e sun-java6-jdk shared/accepted-sun-dlj-v1-1 select true | debconf-set-selections",
# 			unless  => "debconf-get-selections | grep 'sun-java6-jdk.*shared/accepted-sun-dlj-v1-1.*true'",
# 			path    => ["/bin", "/usr/bin"],
# 			before  => Package["java-jdk"],
# 		}
# 	}
#
# 	# Install the JDK package, alias it to
# 	# 'java-jdk' so we don't have
# 	# to care about the real package name later.
# 	package { $jdk_package:
# 		ensure => installed,
# 		alias  => "java-jdk",
# 		require => Package["java-jre"],
# 	}
# }
