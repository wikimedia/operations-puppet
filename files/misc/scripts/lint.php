<?php

if ( isset( $argv[1] ) ) {
	$dir = $argv[1];
	if ( !is_dir( $dir ) ) {
		echo "Not a directory: $dir\n";
		exit( 1 );
	}
} else {
	$dir = '.';
}

if ( !check_dir( $dir ) ){
	exit( 1 );
} else {
	exit( 0 );
}

function check_dir( $dir ) {
	$handle = opendir( $dir );
	if ( !$handle ) {
		return true;
	}
	$success = true;
	while ( false !== ( $fileName = readdir( $handle ) ) ) {
		if ( substr( $fileName, 0, 1 ) == '.' ) {
			continue;
		}
		if ( is_dir( "$dir/$fileName" ) ) {
			$ret = check_dir( "$dir/$fileName" );
		} elseif ( substr( $fileName, -4 ) == '.php' ) {
			$ret = check_file( "$dir/$fileName" );
		} else {
			$ret = true;
		}
		$success = $success && $ret;
	}
	closedir( $handle );
	return $success;
}

function check_file( $file ) {
	static $okErrors = array(
		'Redefining already defined constructor',
		'Assigning the return value of new by reference is deprecated',
	);
	$errors = array();
	parsekit_compile_file( $file, $errors, PARSEKIT_SIMPLE );
	$ret = true;
	if ( $errors ) {
		foreach ( $errors as $error ) {
			foreach ( $okErrors as $okError ) {
				if ( substr( $error['errstr'], 0, strlen( $okError ) ) == $okError ) {
					continue 2;
				}
			}
			$ret = false;
			print "Error in $file line {$error['lineno']}: {$error['errstr']}\n";
		}
	}
	return $ret;
}
