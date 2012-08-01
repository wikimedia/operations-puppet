# Configuration files for apache running on application servers
# note: it uses $cluster for the apache2.conf
#
# requires applicationserver::packages to be in place
class applicationserver::config::apache( $cluster ) {

	require applicationserver::packages

	## FIXME: this is probably a crime against modules. need to redo.
	Class["role::applicationserver::common"] -> Class[apache::files::config::apache]

	file {
		"/etc/apache2/apache2.conf":
			owner => root,
			group => root,
			mode => 0444,
			notify => Service[apache],
			content => template("applicationserver/apache/apache2.conf.erb");
		"/etc/apache2/envvars":
			owner => root,
			group => root,
			mode => 0444,
			notify => Service[apache],
			source => "puppet:///modules/applicationserver/apache/envvars.appserver";
		"/etc/cluster":
			mode => 0444,
			owner => root, 
			group => root, 
			content => $site;
	}
}
