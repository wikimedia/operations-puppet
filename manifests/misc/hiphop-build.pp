# manifests/misc/hiphop.pp
# Manifest to install all packages needed for building HipHop

class misc::hiphop::build {
	package { ["git-core", "cmake", "g++", "libboost1.48-dev", "libmysqlclient-dev", "libxml2-dev",
		"libmcrypt-dev", "libicu-dev", "openssl", "build-essential", "binutils-dev", "libcap-dev",
		"libgd2-xpm-dev", "zlib1g-dev", "libtbb-dev", "libonig-dev", "libpcre3-dev", "autoconf",
		"libtool", "libcurl4-openssl-dev", "libboost-regex1.48-dev", "libboost-system1.48-dev",
		"libboost-program-options1.48-dev", "libboost-filesystem1.48-dev", "wget", "memcached",
		"libreadline-dev", "libncurses-dev", "libmemcached-dev", "libbz2-dev", "libc-client2007e-dev",
		"php5-mcrypt", "php5-imagick", "libgoogle-perftools-dev", "libcloog-ppl0", "libelf-dev",
		"libdwarf-dev", "libunwind7-dev", "subversion"]:
			ensure => latest;
	}
}