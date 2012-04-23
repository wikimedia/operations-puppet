<?php
# check all memcached servers - Nagios plugin

require_once( '/home/w/common/wmf-config/mc.php' );
#$wgMemCachedServers[] = '10.0.2.101:11000';

$OK=0;
$WARNING=1;
$CRITICAL=2;

$statuscode = array( $OK => 'OK', $WARNING => 'WARNING', $CRITICAL => 'CRITICAL' );

$crit_hosts = array();
$message = "Could not connect: ";

function nagios_return( $result, $message ) {
	global $statuscode;

	print "MEMCACHED {$statuscode[$result]} - $message\n";
	exit( $result );
}

foreach ( $wgMemCachedServers as $server ) {
	list( $host, $port ) = explode( ':', $server );

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

nagios_return( $WARNING, "check check_all_memcached.php - we should not be here" );

