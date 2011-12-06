<?php
/**
 * Example for running the TestSwarm MediaWiki fetcher.
 *
 * Licensed under GPL version 2
 *
 * @author Antoine "hashar" Musso, 2011
 * @author Timo Tijhof, 2011
 */

date_default_timezone_set( 'UTC' );

// Choose a mode below and the switch structure will forge options for you!
$mode = 'dev';
$mode = 'preprod';
$mode = 'prod';
if( !(count($argv) === 2 && preg_match( '/^--(dev|preprod|prod)$/', $argv[1] ) ) ) {
	print "$argv[0]: expects exactly one of the following options:\n\n";
	print "  --dev     : fetch only this script repository.\n";
	print "  --preprod : fetch part of phase3 in a temp directory with debugging\n";
	print "  --prod    : fetch phase3 in a real directory without debugging\n";
	print "\nBehavior is hardcoded in this script.\n";
	exit(1);
}
$mode = substr( $argv[1], 2 );

# Magic stuff for lazy people
switch( $mode ) {
	# Options for local debuggings
	case 'dev':
		$options = array(
			'debug' => true,
			'root'  => '/tmp/tsmw-trunk-dev',
			'svnUrl'   => 'http://svn.wikimedia.org/svnroot/mediawiki/trunk/tools/testswarm/scripts',
			'minRev' => 88439,  # will not fetch anything before that rev
		);
		break;

	# Options fetching from phase3. Debug on.
	case 'preprod':
		$options = array(
			'debug' => true,
			'root'  => '/tmp/tsmw-trunk-preprod',
			'svnUrl'   => 'http://svn.wikimedia.org/svnroot/mediawiki/trunk/phase3',
			'minRev' => 101591,
		);
		break;

	case 'prod':
		$options = array(
			'debug'  => false,
			'root'   => '/var/lib/testswarm/mediawiki-trunk',
			'svnUrl' => 'http://svn.wikimedia.org/svnroot/mediawiki/trunk/phase3',
			'testPattern' => '/checkouts/mw/trunk/r$1/tests/qunit/?filter=$2',
			'minRev' => 105305,
		);
		break;

	default:
		print "Mode $mode unimplemented. Please edit ".__FILE__."\n";
		exit( 1 );
}

require_once( __DIR__ . '/testswarm-mw-fetcher.php' );

$main = new TestSwarmMWMain( $options );
$rev = $main->tryFetchNextRev();

if( $rev === false ) {
	print "No new revision, nothing left to do. Exiting.\n";
	exit;
}

$fetcher_conf = parse_ini_file( "/etc/testswarm/fetcher.ini", true );

// Fix up database file permission
$paths = $main->getPathsForRev( $rev );
$dbFile = $paths['db'] . "/r{$rev}.sqlite";
chgrp( $dbFile, $fetcher_conf['TestSwarmAPI']['wwwusergroup'] );
chmod( $dbFile, 0664 );

// Submit a new job to TestSwarm
$api = new TestSwarmAPI(
	$main
	, $fetcher_conf['TestSwarmAPI']['username']
	, $fetcher_conf['TestSwarmAPI']['authtoken']
	, $fetcher_conf['TestSwarmAPI']['url']
);
$api->doAddJob( $rev );
