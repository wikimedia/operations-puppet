<?php

require_once( '/usr/local/apache/common-local/wmf-config/mc.php' );
#$wgMemCachedServers[] = '10.0.2.101:11000';

$OK=0;
$WARNING=1;
$CRITICAL=2;

$statuscode = array( $OK => 'OK', $WARNING => 'WARNING', $CRITICAL => 'CRITICAL' );


function nagios_return( $result, $message ) {
	global $statuscode;

	print "MEMCACHED {$statuscode[$result]} - $message\n";
	exit( $result );
}

foreach ( $wgMemCachedServers as $server ) {
	list( $host, $port ) = explode( ':', $server );

	$fp = @fsockopen( $host, $port, $errno, $errstr, 3 );

	if ( !$fp ) {
		nagios_return( $CRITICAL, "Can not connect to $host:$port ($errstr)" );
	} else {

        	@fwrite($fp, "stats\r\n");
        	stream_set_timeout($fp, 2);
        	$res = @fread($fp, 2000);

        	$info = @stream_get_meta_data($fp);
        	fclose($fp);


        	if ($info['timed_out']) {
                	nagios_return( $CRITICAL, "Timeout reading from $host:$port" );
        	}
	}
}

nagios_return( $OK, "All memcacheds are online" );
