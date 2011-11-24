<?php
/**
 * Helper functions for Swift related image thumbnail purging.
 * The functions here should only be called after MediaWiki setup.
 * 
 * $wmfSwiftConfig must reside in PrivateSettings.php. It should also
 * be extracted in CommonSettings.php to set any swift backend settings.
 * 
 * This file belongs under wmf-config/ and should be included by CommonSettings.php.
 */

# Swift API client module and helper functions
require_once( '/usr/local/apache/common-local/lib/php-cloudfiles/cloudfiles.php' );

/**
 * Handler for the LocalFilePurgeThumbnails hook.
 * To avoid excess inclusion of cloudfiles.php, a hook handler can be added
 * to CommonSettings.php which includes this file and calls this function.
 * 
 * @param $file File
 * @param $archiveName string|false
 * @return true
 */
function wmfPurgeBackendThumbCache( File $file, $archiveName ) {
	global $site, $lang; // CommonSettings.php

	if ( $archiveName !== false ) {
		$thumbRel = $file->getArchiveThumbRel( $archiveName ); // old version
	} else {
		$thumbRel = $file->getRel(); // current version
	}

	$container = wmfGetSwiftThumbContainer( $site, $lang );
	if ( $container ) { // sanity
		$files = $container->list_objects( 0, NULL, "$thumbRel/" );
		foreach ( $files as $file ) {
			$name = "{$thumbRel}/{$file}"; // swift object name
			try {
				$container->delete_object( $name );
			} catch ( NoSuchObjectException $e ) { // probably a race condition
				wfDebugLog( 'swiftThumb', "Could not delete `{$name}`; object does not exist." );
			}
		}
	}

	return true;
}

/**
 * Get the Swift thumbnail container for this wiki.
 * 
 * @param $site string
 * @param $lang string
 * @return CF_Container|null
 */
function wmfGetSwiftThumbContainer( $site, $lang ) {
	global $wmfSwiftConfig; // PrivateSettings.php

	$auth = new CF_Authentication(
		$wmfSwiftConfig['user'],
		$wmfSwiftConfig['key'],
		NULL,
		$wmfSwiftConfig['authUrl']
	);
	$auth->authenticate();

	$conn = new CF_Connection( $auth );

	$name = "{$site}-{$lang}-images-thumb"; // swift container name
	try {
		$container = $conn->get_container( $name );
	} catch ( NoSuchContainerException $e ) { // container not created yet
		$container = null;
		wfDebugLog( 'swiftThumb', "Could not access `{$name}`; container does not exist." );
	}

	return $container;
}
