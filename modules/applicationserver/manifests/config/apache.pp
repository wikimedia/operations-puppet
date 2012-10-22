# Configuration files for apache running on application servers
# note: it uses $cluster for the apache2.conf
#
# requires applicationserver::packages to be in place
class applicationserver::config::apache(
	$maxclients="40"
	) {

	Class["applicationserver::packages"] -> Class["applicationserver::config::apache"]

	file {
		"/etc/apache2/apache2.conf":
			owner => root,
			group => root,
			mode => 0444,
			content => template("applicationserver/apache/apache2.conf.erb");
		"/etc/apache2/envvars":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///modules/applicationserver/apache/envvars.appserver";
		"/etc/cluster":
			mode => 0444,
			owner => root,
			group => root,
			content => $::site;
	}

	Class["applicationserver::config::apache"] -> Class["applicationserver::config::base"]
}
