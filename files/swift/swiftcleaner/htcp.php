<?

// I expect to call this script with one argument - the URL to purge
HTCPPurge($argv[1]);

function HTCPPurge( $url ) {

	//global $wgHTCPMulticastAddress, $wgHTCPMulticastTTL, $wgHTCPPort;
	$wgHTCPMulticastAddress = "239.128.0.112";
	$wgHTCPMulticastTTL = 10;
	$wgHTCPPort = 4827;

	$htcpOpCLR = 4; // HTCP CLR

	// @todo FIXME: PHP doesn't support these socket constants (include/linux/in.h)
	if( !defined( "IPPROTO_IP" ) ) {
		define( "IPPROTO_IP", 0 );
		define( "IP_MULTICAST_LOOP", 34 );
		define( "IP_MULTICAST_TTL", 33 );
	}

	// pfsockopen doesn't work because we need set_sock_opt
	$conn = socket_create( AF_INET, SOCK_DGRAM, SOL_UDP );
	if ( $conn ) {
		// Set socket options
		socket_set_option( $conn, IPPROTO_IP, IP_MULTICAST_LOOP, 0 );
		if ( $wgHTCPMulticastTTL != 1 )
			socket_set_option( $conn, IPPROTO_IP, IP_MULTICAST_TTL,
				$wgHTCPMulticastTTL );

		//if( !is_string( $url ) ) {
		//	throw new MWException( 'Bad purge URL' );
		//}
		//$url = SquidUpdate::expand( $url );

		// Construct a minimal HTCP request diagram
		// as per RFC 2756
		// Opcode 'CLR', no response desired, no auth
		$htcpTransID = rand();

		$htcpSpecifier = pack( 'na4na*na8n',
			4, 'HEAD', strlen( $url ), $url,
			8, 'HTTP/1.0', 0 );

		$htcpDataLen = 8 + 2 + strlen( $htcpSpecifier );
		$htcpLen = 4 + $htcpDataLen + 2;

		// Note! Squid gets the bit order of the first
		// word wrong, wrt the RFC. Apparently no other
		// implementation exists, so adapt to Squid
		$htcpPacket = pack( 'nxxnCxNxxa*n',
			$htcpLen, $htcpDataLen, $htcpOpCLR,
			$htcpTransID, $htcpSpecifier, 2);

		// Send out
		//wfDebug( "Purging URL $url via HTCP\n" );
		socket_sendto( $conn, $htcpPacket, $htcpLen, 0,
			$wgHTCPMulticastAddress, $wgHTCPPort );
	} else {
		$errstr = socket_strerror( socket_last_error() );
		//wfDebug( __METHOD__ . "(): Error opening UDP socket: $errstr\n" );
	}
}
?>
