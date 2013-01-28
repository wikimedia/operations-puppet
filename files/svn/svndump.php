#!/usr/bin/php
<?php
# Use for Wikimedia internal SVN dumps
# Designed to dump to a specific location. Amanda handles the long-term storage from $baseDumpPath/dumps/

### CONFIG ###
$repos = array( 'pywikipedia', 'wikimedia' );
$publicCopies = array();
$baseDumpPath = '/svnroot/bak';
### STOP ###

if( isset( $argv[1] ) && $argv[1] == 'setup' ) {
	exec( "rm -fR $baseDumpPath" );
	mkdir( $baseDumpPath, 0700, true );
	mkdir( "$baseDumpPath/dumps", 0700 );

	foreach( $repos as $repo ) {
		file_put_contents( "$baseDumpPath/lastdumpedname-$repo", 'none' );
		file_put_contents( "$baseDumpPath/lastdumpedrev-$repo", '0' );
	}
	exit;
}

$dayOfWeek = date( 'l' );

foreach( $repos as $repo ) {
	$repoPath = "/svnroot/$repo";
	$lastDumpName = "$baseDumpPath/lastdumpedname-$repo";
	$counterFile = "$baseDumpPath/lastdumpedrev-$repo";
	$latestAvailableRev = intval( exec( "svnlook youngest $repoPath" ) );
	$lastDumpedRev = 0;
	$baseCmd = "svnadmin dump";

	# Get rid of yesterday's dump, Amanda already got it
	$df = file_get_contents( $lastDumpName );
	if( $df !== 'none' ) {
		unlink( $df );
	}

	# Not sunday, do an incremental
	if( $dayOfWeek != 'Sunday' ) {
		$lastDumpedRev = intval( file_get_contents( $counterFile  ) ) + 1;
		$baseCmd .= " --incremental";
	}

	$uniqueFile = "$repo-svndump-" . date( 'Ymd' ) . "-revs$lastDumpedRev:$latestAvailableRev.gz";
	$fileName = "$baseDumpPath/dumps/$uniqueFile";
	# dump, gzip, write
	print "Dumping repo: $repo, revs $lastDumpedRev-$latestAvailableRev\n";
	exec( "$baseCmd --deltas --revision $lastDumpedRev:$latestAvailableRev $repoPath | gzip -9 > $fileName" );

	if( $dayOfWeek == 'Sunday' && isset( $weeklyPublicCopies[$repo] ) ) {
		$pubPath = $weeklyPublicCopies[$repo];
		foreach( $glob( "$pubPath/$repo-svndump-*.gz" ) as $olddump ) unlink( $olddump );
		copy( $fileName, "$pubPath/$uniqueFile" );
	}

	# Increment our counter for last dumped rev
	file_put_contents( $counterFile, $latestAvailableRev );
	file_put_contents( $lastDumpName, $fileName );
}

print "Done";
