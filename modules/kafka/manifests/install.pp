# == Class kafka::install
#
class kafka::install {
	package { "kafka": ensure => "installed" }
}