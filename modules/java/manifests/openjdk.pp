# Class used to install an OpenJDK package
#
# Parameters:
#  $version  - An OpenJDK version such as 6, 1.7 (default: ubuntu)
#              Puppet will fail whenever the version is not recognized.
#  $ensure   - Either 'present', 'latest' or 'absent'. This is passed to the
#              package {} directive (default: present).
#  $jdk      - Whether to include the JDK (default: false).
#

class java::openjdk::applyboth {
	java::openjdk { 'jdk6': version => '1.6', jdk => true, }
  java::openjdk { 'jdk7': version => '1.7', jdk => true, }
}

define java::openjdk(
	$version='ubuntu',
	$ensure='present',
	$jdk=false,
 ) {

	$pkg_prefix = $version ? {

		'6'      => 'openjdk-6',
		'1.6'    => 'openjdk-6',

		'7'      => 'openjdk-7',
		'1.7'    => 'openjdk-7',

		'ubuntu' => 'default',

		# Unrecognized version :(
		default  => undef,
	}

	if( !$pkg_prefix ) {
		fail("Unrecognized OpenJDK version '${version}'")
	}

	if( $jdk ) {
		package { "${pkg_prefix}-jdk":
			ensure => $ensure,
		}
	}

	package { "${pkg_prefix}-jre":
		ensure => $ensure,
	}

}
