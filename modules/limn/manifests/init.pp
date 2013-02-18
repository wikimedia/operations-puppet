# == Class limn
# Installs limn.
# To spawn up a limn server instance, use the limn::instance define.
class limn(
	$var_directory  = "/var/lib/limn",
	$log_directory  = "/var/log/limn",
	$user           = "limn",
	$group          = "limn",
) {
	package { "limn": ensure => present }

	# Default limn containing data directory.
	# Instances default to storing data in
	# $var_directory/$name
	file { $var_directory:
		owner  => $user,
		group  => $group,
		mode   => "0755",
		ensure => "directory",
	}

	# Default limn log directory.
	# Instances will log to
	# $log_directory/limn-$name.log
	file { $log_directory:
		owner  => $user,
		group  => $group,
		mode   => "0755",
		ensure => "directory",
	}
}