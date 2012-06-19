<?php
# check all memcached servers - Nagios plugin

# new method to get mc.php, avoid NFS, rather fetch it from noc http
$buffer=file_get_contents("http://noc.wikimedia.org/conf/mc.php.txt");

# cut off at string RELOCATED to get active servers only
$buffer=explode("RELOCATED",$buffer);

# match for IP:11000 strings
preg_match_all("/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:11000/", $buffer[0], $matches);
$wgMemCachedServers=$matches[0];

#DEBUG# print_r($wgMemCachedServers);

# we can't simply do the following due to security config
# http:// wrapper is disabled in the server configuration by allow_url_include=0
# require_once( 'http://noc.wikimedia.org/conf/mc.php.txt' );

# old method to get mc.php - relies on NFS, which is a -1
# but as of today (20120427) you could also still use it if there are any issues with the new way
# require_once( '/home/w/common/wmf-config/mc.php' );

# should stay commented. was here for debug.
#$wgMemCachedServers[] = '10.0.2.101:11000';

$OK=0;
$WARNING=1;
$CRITICAL=2;

$statuscode = array( $OK => 'OK', $WARNING => 'WARNING', $CRITICAL => 'CRITICAL' );

$crit_hosts = array();
$message = "Could not connect: ";
$hosts_string="";

function nagios_return( $result, $message ) {
	global $statuscode;

	print "MEMCACHED {$statuscode[$result]} - $message\n";
	exit( $result );
}

if (isset($wgMemCachedServers)) {

	foreach ( $wgMemCachedServers as $server ) {
		list( $host, $port ) = explode( ':', $server );

		#DEBUG# echo "connecting to host: $host\n";
		$fp = @fsockopen( $host, $port, $errno, $errstr, 3 );

		if ( !$fp ) {
			$crit_hosts[] = "${host}:${port} ($errstr) ";
		} else {
			@fwrite($fp, "stats\r\n");
			stream_set_timeout($fp, 2);
			$res = @fread($fp, 2000);
			$info = @stream_get_meta_data($fp);
			fclose($fp);


			if ($info['timed_out']) {
				$crit_hosts[] = "${host}:${port} (timeout) ";
			}
		}
	}


	if (count($crit_hosts) == 0 ) {
		nagios_return( $OK, "All memcacheds are online" );
	} else {
		foreach ( $crit_hosts as $crit_host ) {
			$hosts_string .= $crit_host;
		}
		nagios_return( $CRITICAL, "${message} ${hosts_string}" );
	}

} else {

nagios_return( $WARNING, "check check_all_memcached.php or mc.php - we should not be here" );

}
