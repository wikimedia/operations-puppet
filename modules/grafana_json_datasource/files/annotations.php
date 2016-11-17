<?php

/**
 * @author Addshore
 * @license GPLv2+
 *
 * Simple endpoint conforming to spec laid out at
 * https://github.com/grafana/simple-json-datasource
 *
 * @TODO
 *  - Only provide annotations for the given range?
 */

if ( $_SERVER['REQUEST_METHOD'] === 'OPTIONS' ) {
	header('Access-Control-Allow-Headers:accept, content-type');
	header('Access-Control-Allow-Methods:POST');
	header('Access-Control-Allow-Origin:*');
	return;
}


if ( $_SERVER['REQUEST_METHOD'] === 'POST' ) {
	$requestBody = file_get_contents('php://input');
	$request = json_decode( $requestBody, true );

	if ( $request === null ) {
		die( 'Bad request JSON.' );
	}

	$query = trim( strtok( $request['annotation']['query'], ' ' ), '#' );

	if ( strpos( $query, 'metawiki:' ) !== 0 ) {
		die( 'Couldn\'t find metawiki: prefix.' );
	}
	$pageTitle = substr( $query, 9 );

	$pageUrl = 'https://meta.wikimedia.org/wiki/' . $pageTitle . '?action=raw';
	$pageBody = file_get_contents( $pageUrl );

	if( $pageBody === false ) {
		die( 'Request to ' . $pageUrl . ' failed.' );
	}

	$data = json_decode( $pageBody, true );

	if ( $data === null ) {
		die( 'Bad page JSON.' );
	}

	$response = array();

	foreach( $data as $annotationData ) {

		if ( $annotationData['start'] == $annotationData['end'] ) {
			$response[] = array(
				'annotation' => $request['annotation'],
				'title' => 'Event',
				'time' => strval( strtotime( $annotationData['start'] ) ) . '000',
				'text' => $annotationData['note'],
			);
		} else {
			$response[] = array(
				'annotation' => $request['annotation'],
				'title' => 'Start Event',
				'time' => strval( strtotime( $annotationData['start'] ) ) . '000',
				'text' => 'Start: ' . $annotationData['note'],
			);
			$response[] = array(
				'annotation' => $request['annotation'],
				'title' => 'End Event',
				'time' => strval( strtotime( $annotationData['end'] ) ) . '000',
				'text' => 'End: ' . $annotationData['note'],
			);
		}
	}

	header( 'Access-Control-Allow-Origin: *' );
	echo json_encode( $response );
	return;
}

die( 'Request must be POST or OPTIONS.' );
