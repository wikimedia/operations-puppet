<?php
/**
 * DCAT-AP generation for Wikibase
 *
 * @author Lokal_Profil
 * @licence MIT
 *
 */

/**
 * Validate that config is json and contains all necessary keys
 * @param array: config
 */
function validateConfig( $config ) {
	if ( !isset( $config ) ) {
		exit( "Could not read the config file. Are you sure it is valid json?" );
	}
	// Later tests depend on these existing and being defined
	$topBool = array( "api-enabled", "dumps-enabled" );
	foreach  ( $topBool as $val ) {
		if ( !array_key_exists( $val, $config ) ) {
			exit( "$val is missing from the config file" );
		}
		elseif ( !is_bool( $config[$val] ) ) {
			exit( "$val in the config file must be a boolean" );
		}
	}

	// Always required
	$top = array(
		"directory", "uri", "themes", "keywords", "publisher",
		"contactPoint", "ld-info", "catalog-license", "catalog-homepage",
		"catalog-i18n", "catalog-issued"
	);
	$sub = array(
		"publisher" => array( "publisherType", "homepage", "name", "email" ),
		"contactPoint" => array( "vcardType", "name", "email" ),
		"ld-info" => array( "accessURL", "mediatype", "license" )
	);

	// Dependent on topBool
	if ( $config['api-enabled'] ) {
		array_push( $top, "api-info" );
		$sub["api-info"] = array( "accessURL", "mediatype", "license" );
	}
	if ( $config['dumps-enabled'] ) {
		array_push( $top, "dump-info" );
		$sub["dump-info"] = array( "accessURL", "mediatype", "license" );
	}

	// Test
	foreach  ( $top as $val ) {
		if ( !array_key_exists( $val, $config ) ) {
			exit( "$val is missing from the config file" );
		}
	}
	foreach  ( $sub as $key => $subArray ) {
		foreach  ( $subArray as $val ) {
			if ( !array_key_exists( $val, $config[$key] ) ) {
				exit( $key . "[" . $val . "] is missing from the config file" );
			}
		}
	}
}

/**
 * Construct a data blob as an easy way of passing data around.
 * @param string: path to config file
 * @return array: A data blob
 */
function makeDataBlob( $config ) {
	// Open config file and languages
	$config = json_decode( file_get_contents( $config ), true );
	validateConfig( $config );

	// identify existing i18n files
	$langs = array();
	foreach ( scandir( 'i18n' ) as $key  => $filename ) {
		if ( substr( $filename, -strlen( '.json' ) ) === '.json' && $filename !== 'qqq.json' ) {
			$langs[substr( $filename, 0, -strlen( '.json' ) )] = "i18n/$filename";
		}
	}

	// load i18n files into i18n object
	$i18n = array();
	foreach ( $langs as $langCode => $filename ) {
		$i18n[$langCode] = json_decode( file_get_contents( $filename ), true );
	}

	// load catalog i18n info from URL and add to i18n object
	$i18nJSON = json_decode( file_get_contents( $config['catalog-i18n'] ), true );
	if ( !isset( $i18nJSON ) ) {
		exit(
			"Could not read catalog-i18n. Are you sure " .
			$config['catalog-i18n'] .
			" exists and is valid json?"
		);
	}
	foreach ( array_keys( $i18n ) as $langCode ) {
		if ( array_key_exists( "$langCode-title", $i18nJSON ) ) {
			$i18n[$langCode]['catalog-title'] = $i18nJSON["$langCode-title"];
		}
		if ( array_key_exists( "$langCode-description", $i18nJSON ) ) {
			$i18n[$langCode]['catalog-description'] = $i18nJSON["$langCode-description"];
		}
	}

	// hardcoded ids (for now at least)
	// issue #2
	$ids = array(
		'publisher' => '_n42',
		'contactPoint' => '_n43',
		'liveDataset' => 'liveData',
		'dumpDatasetPrefix' => 'dumpData',
		'liveDistribLD' => 'liveDataLD',
		'liveDistribAPI' => 'liveDataAPI',
		'dumpDistribPrefix' => 'dumpDist',
	);

	// stick loaded data into blob
	$data = array(
		'config' => $config,
		'dumps' => null,
		'i18n' => $i18n,
		'ids' => $ids,
	);
	return $data;
}

/**
 * Add additional data to a distribution entry when dealing with a dump.
 * Complement to writeDistribution()
 *
 * @param XmlWriter $xml XML stream to write to
 * @param array $data data-blob of i18n and config variables
 * @param string $dumpDate the date of the dumpfile, null for live data
 */
function dumpDistributionExtras( XMLWriter $xml, $data, $dumpDate, $format ) {
	$url = str_replace(
		'$1',
		$dumpDate . '/' . $data['dumps'][$dumpDate][$format]['filename'],
		$data['config']['dump-info']['accessURL']
	);

	$xml->startElementNS( 'dcat', 'accessURL', null );
	$xml->writeAttributeNS( 'rdf', 'resource', null, $url );
	$xml->endElement();

	$xml->startElementNS( 'dcat', 'downloadURL', null );
	$xml->writeAttributeNS( 'rdf', 'resource', null, $url );
	$xml->endElement();

	$xml->writeElementNS( 'dcterms', 'issued', null,
		$data['dumps'][$dumpDate][$format]['timestamp'] );

	$xml->startElementNS( 'dcat', 'byteSize', null );
	$xml->writeAttributeNS( 'rdf', 'datatype', null,
		'http://www.w3.org/2001/XMLSchema#decimal' );
	$xml->text( $data['dumps'][$dumpDate][$format]['byteSize'] );
	$xml->endElement();
}

/**
 * Construct distribution entry for each format in which a distribution
 * is available. The DCAT-specification requires each format to be a
 * separate distribution.
 *
 * @param XmlWriter $xml XML stream to write to
 * @param array $data data-blob of i18n and config variables
 * @param string $distribId id for the distribution
 * @param string $prefix prefix for corresponding entry in config file
 * @param string $dumpDate the date of the dumpfile, null for live data
 */
function writeDistribution( XMLWriter $xml, $data, $distribId, $prefix, $dumpDate ) {
	$ids = array();

	foreach ( $data['config']["$prefix-info"]['mediatype'] as $format => $mediatype ) {
		$id = $data['config']['uri'] . '#' . $distribId . $dumpDate . $format;
		array_push( $ids, $id );

		$xml->startElementNS( 'rdf', 'Description', null );
		$xml->writeAttributeNS( 'rdf', 'about', null, $id );

		$xml->startElementNS( 'rdf', 'type', null );
		$xml->writeAttributeNS( 'rdf', 'resource', null,
			'http://www.w3.org/ns/dcat#Distribution' );
		$xml->endElement();

		$xml->startElementNS( 'dcterms', 'license', null );
		$xml->writeAttributeNS( 'rdf', 'resource', null,
			$data['config']["$prefix-info"]['license'] );
		$xml->endElement();

		if ( is_null( $dumpDate ) ) {
			$xml->startElementNS( 'dcat', 'accessURL', null );
			$xml->writeAttributeNS( 'rdf', 'resource', null,
				$data['config']["$prefix-info"]['accessURL'] );
			$xml->endElement();
		}
		else {
			dumpDistributionExtras( $xml, $data, $dumpDate, $format );
		}

		$xml->writeElementNS( 'dcterms', 'format', null, $mediatype );

		// add description in each language
		foreach ( $data['i18n'] as $langCode => $langData ) {
			if ( array_key_exists( "distribution-$prefix-description", $langData ) ) {
				$xml->startElementNS( 'dcterms', 'description', null );
				$xml->writeAttributeNS( 'xml', 'lang', null, $langCode );
				$xml->text(
					str_replace( '$1', $format, $langData["distribution-$prefix-description"] )
				);
				$xml->endElement();
			}
		}

		$xml->endElement();
	}

	return $ids;
}

/**
 * Construct a dataset entry
 *
 * @param XmlWriter $xml XML stream to write to
 * @param array $data data-blob of i18n and config variables
 * @param string $dumpDate the date of the dumpfile, null for live data
 * @param string $datasetId the id of the dataset
 * @param string $publisher the nodeId of the publisher
 * @param string $contactPoint the nodeId of the contactPoint
 * @param array $distribution array of the distribution identifiers
 */
function writeDataset( XMLWriter $xml, $data, $dumpDate, $datasetId,
	$publisher, $contactPoint, $distribution ) {

	$type = 'dump';
	if ( is_null( $dumpDate ) ) {
		$type = 'live';
	}

	$id = $data['config']['uri'] . '#' . $datasetId . $dumpDate;

	$xml->startElementNS( 'rdf', 'Description', null );
	$xml->writeAttributeNS( 'rdf', 'about', null, $id );

	$xml->startElementNS( 'rdf', 'type', null );
	$xml->writeAttributeNS( 'rdf', 'resource', null,
		'http://www.w3.org/ns/dcat#Dataset' );
	$xml->endElement();

	$xml->startElementNS( 'adms', 'contactPoint', null );
	$xml->writeAttributeNS( 'rdf', 'nodeID', null, $contactPoint );
	$xml->endElement();

	$xml->startElementNS( 'dcterms', 'publisher', null );
	$xml->writeAttributeNS( 'rdf', 'nodeID', null, $publisher );
	$xml->endElement();

	if ( $type === 'live' ) {
		$xml->startElementNS( 'dcterms', 'accrualPeriodicity', null );
		$xml->writeAttributeNS( 'rdf', 'resource', null,
			'http://purl.org/cld/freq/continuous' );
		$xml->endElement();
	}

	// add keywords
	foreach ( $data['config']['keywords'] as $key => $keyword ) {
		$xml->writeElementNS( 'dcat', 'keyword', null, $keyword );
	}

	// add themes
	foreach ( $data['config']['themes'] as $key => $keyword ) {
		$xml->startElementNS( 'dcat', 'theme', null );
		$xml->writeAttributeNS( 'rdf', 'resource', null,
			"http://eurovoc.europa.eu/$keyword" );
		$xml->endElement();
	}

	// add title and description in each language
	foreach ( $data['i18n'] as $langCode => $langData ) {
		if ( array_key_exists( "dataset-$type-title", $langData ) ) {
			$xml->startElementNS( 'dcterms', 'title', null );
			$xml->writeAttributeNS( 'xml', 'lang', null, $langCode );
			if ( $type === 'live' ) {
				$xml->text( $langData['dataset-live-title'] );
			}
			else {
				$xml->text(
					str_replace( '$1', $dumpDate, $langData['dataset-dump-title'] )
			   );
			}
			$xml->endElement();
		}
		if ( array_key_exists( "dataset-$type-description", $langData ) ) {
			$xml->startElementNS( 'dcterms', 'description', null );
			$xml->writeAttributeNS( 'xml', 'lang', null, $langCode );
			$xml->text( $langData["dataset-$type-description"] );
			$xml->endElement();
		}
	}

	// add distributions
	foreach ( $distribution as $key => $value ) {
		$xml->startElementNS( 'dcat', 'distribution', null );
		$xml->writeAttributeNS( 'rdf', 'resource', null, $value );
		$xml->endElement();
	}

	$xml->endElement();
	return $id;
}

/**
 * Construct the publisher for the catalog and datasets with a given nodeId
 *
 * @param XmlWriter $xml XML stream to write to
 * @param array $data data-blob of i18n and config variables
 * @param string $publisher the nodeId of the publisher
 */
function writePublisher( XMLWriter $xml, $data, $publisher ) {
	$xml->startElementNS( 'rdf', 'Description', null );
	$xml->writeAttributeNS( 'rdf', 'nodeID', null, $publisher );

	$xml->startElementNS( 'rdf', 'type', null );
	$xml->writeAttributeNS( 'rdf', 'resource', null,
		'http://xmlns.com/foaf/0.1/Agent' );
	$xml->endElement();

	$xml->writeElementNS( 'foaf', 'name', null,
		$data['config']['publisher']['name'] );

	$xml->startElementNS( 'dcterms', 'type', null );
	$xml->writeAttributeNS( 'rdf', 'resource', null,
		'http://purl.org/adms/publishertype/' .
			$data['config']['publisher']['publisherType'] );
	$xml->endElement();

	$xml->writeElementNS( 'foaf', 'homepage', null,
		$data['config']['publisher']['homepage'] );

	$xml->startElementNS( 'vcard', 'hasEmail', null );
	$xml->writeAttributeNS( 'rdf', 'resource', null,
		'mailto:' . $data['config']['publisher']['email'] );
	$xml->endElement();

	$xml->endElement();
}

/**
 * Construct a contactPoint for the datasets with a given nodeId
 *
 * @param XmlWriter $xml XML stream to write to
 * @param array $data data-blob of i18n and config variables
 * @param string $contactPoint the nodeId of the contactPoint
 */
function writeContactPoint( XMLWriter $xml, $data, $contactPoint ) {
	$xml->startElementNS( 'rdf', 'Description', null );
	$xml->writeAttributeNS( 'rdf', 'nodeID', null, $contactPoint );

	$xml->startElementNS( 'rdf', 'type', null );
	$xml->writeAttributeNS( 'rdf', 'resource', null,
		'http://www.w3.org/2006/vcard/ns#' .
			$data['config']['contactPoint']['vcardType'] );
	$xml->endElement();

	$xml->startElementNS( 'vcard', 'hasEmail', null );
	$xml->writeAttributeNS( 'rdf', 'resource', null,
		'mailto:' . $data['config']['contactPoint']['email'] );
	$xml->endElement();

	$xml->writeElementNS( 'vcard', 'fn', null,
		$data['config']['contactPoint']['name'] );

	$xml->endElement();
}

/**
 * Construct the catalog entry
 *
 * @param XmlWriter $xml XML stream to write to
 * @param array $data data-blob of i18n and config variables
 * @param string $publisher the nodeId of the publisher
 * @param array $dataset array of the dataset identifiers
 */
function writeCatalog( XMLWriter $xml, $data, $publisher, $dataset ) {
	$xml->startElementNS( 'rdf', 'Description', null );
	$xml->writeAttributeNS( 'rdf', 'about', null,
		$data['config']['uri'] . '#catalog' );

	$xml->startElementNS( 'rdf', 'type', null );
	$xml->writeAttributeNS( 'rdf', 'resource', null,
		'http://www.w3.org/ns/dcat#Catalog' );
	$xml->endElement();

	$xml->startElementNS( 'dcterms', 'license', null );
	$xml->writeAttributeNS( 'rdf', 'resource', null,
		$data['config']['catalog-license'] );
	$xml->endElement();

	$xml->startElementNS( 'dcat', 'themeTaxonomy', null );
	$xml->writeAttributeNS( 'rdf', 'resource', null,
		'http://eurovoc.europa.eu/' );
	$xml->endElement();

	$xml->writeElementNS( 'foaf', 'homepage', null,
		$data['config']['catalog-homepage'] );
	$xml->writeElementNS( 'dcterms', 'modified', null, date( 'Y-m-d' ) );
	$xml->writeElementNS( 'dcterms', 'issued', null,
		$data['config']['catalog-issued'] );

	$xml->startElementNS( 'dcterms', 'publisher', null );
	$xml->writeAttributeNS( 'rdf', 'nodeID', null, $publisher );
	$xml->endElement();

	// add language, title and description in each language
	foreach ( $data['i18n'] as $langCode => $langData ) {
		$xml->startElementNS( 'dcterms', 'language', null );
		$xml->writeAttributeNS( 'rdf', 'resource', null,
			"http://id.loc.gov/vocabulary/iso639-1/$langCode" );
		$xml->endElement();

		if ( array_key_exists( 'catalog-title', $langData ) ) {
			$xml->startElementNS( 'dcterms', 'title', null );
			$xml->writeAttributeNS( 'xml', 'lang', null, $langCode );
			$xml->text( $langData['catalog-title'] );
			$xml->endElement();
		}
		if ( array_key_exists( 'catalog-description', $langData ) ) {
			$xml->startElementNS( 'dcterms', 'description', null );
			$xml->writeAttributeNS( 'xml', 'lang', null, $langCode );
			$xml->text( $langData['catalog-description'] );
			$xml->endElement();
		}
	}

	// add datasets
	foreach ( $dataset as $key => $value ) {
		$xml->startElementNS( 'dcat', 'dataset', null );
		$xml->writeAttributeNS( 'rdf', 'resource', null, $value );
		$xml->endElement();
	}

	$xml->endElement();
}

/**
 * Construct the whole DCAT-AP document given an array of dump info
 *
 * @param array $data data-blob of i18n and config variables
 * @return string: xmldata
 */
function outputXml( $data ) {
	// Setting XML header
	@header ( 'content-type: text/xml charset=UTF-8' );

	// Initializing the XML Object
	$xml = new XmlWriter();
	$xml->openMemory();
	$xml->setIndent( true );
	$xml->setIndentString( '    ' );

	// set namespaces
	$xml->startDocument( '1.0', 'UTF-8' );
	$xml->startElementNS( 'rdf', 'RDF', null );
	$xml->writeAttributeNS( 'xmlns', 'rdf', null,
		'http://www.w3.org/1999/02/22-rdf-syntax-ns#' );
	$xml->writeAttributeNS( 'xmlns', 'dcterms', null,
		'http://purl.org/dc/terms/' );
	$xml->writeAttributeNS( 'xmlns', 'dcat', null,
		'http://www.w3.org/ns/dcat#' );
	$xml->writeAttributeNS( 'xmlns', 'foaf', null,
		'http://xmlns.com/foaf/0.1/' );
	$xml->writeAttributeNS( 'xmlns', 'adms', null,
		'http://www.w3.org/ns/adms#' );
	$xml->writeAttributeNS( 'xmlns', 'vcard', null,
		'http://www.w3.org/2006/vcard/ns#' );

	// Calls previously declared functions to construct xml
	writePublisher( $xml, $data, $data['ids']['publisher'] );
	writeContactPoint( $xml, $data, $data['ids']['contactPoint'] );

	$dataset = array();

	// Live dataset and distributions
	$liveDistribs = writeDistribution( $xml, $data,
		$data['ids']['liveDistribLD'], 'ld', null );
	if ( $data['config']['api-enabled'] ) {
		$liveDistribs = array_merge( $liveDistribs,
			writeDistribution( $xml, $data,
				$data['ids']['liveDistribAPI'], 'api', null )
		);
	}
	array_push( $dataset,
		writeDataset( $xml, $data, null, $data['ids']['liveDataset'],
			$data['ids']['publisher'], $data['ids']['contactPoint'],
			$liveDistribs )
	);

	// Dump dataset and distributions
	if ( $data['config']['dumps-enabled'] ) {
		foreach ( $data['dumps'] as $key => $value ) {
			$distIds = writeDistribution( $xml, $data,
				$data['ids']['dumpDistribPrefix'], 'dump', $key );
			array_push( $dataset,
				writeDataset( $xml, $data, $key,
					$data['ids']['dumpDatasetPrefix'],
					$data['ids']['publisher'],
					$data['ids']['contactPoint'], $distIds )
			);
		}
	}

	writeCatalog( $xml, $data, $data['ids']['publisher'], $dataset );

	// Closing last XML node
	$xml->endElement();

	// Printing the XML
	return $xml->outputMemory( true );
}

/**
 * Given a dump directory produce array with data needed by outputXml()
 *
 * @param string $dirname directory name
 * @return array: of dumpdata, or empty array
 */
function scanDump( $dirname, $data ) {
	$teststrings = array();
	foreach ( $data['config']['dump-info']['mediatype'] as $fileEnding => $mediatype ) {
		$teststrings[$fileEnding] = 'all.' . $fileEnding . '.gz';
	}

	$dumps = array();

	foreach ( scandir( $dirname ) as $dirKey  => $subdir ) {
		// get rid of files and non-relevant sub-directories
		if ( substr( $subdir, 0, 1 ) != '.' && is_dir( $dirname . '/' . $subdir ) ) {
			// each subdir refers to a timestamp
			$subDump = array();
			foreach ( scandir( $dirname . '/' . $subdir ) as $key  => $filename ) {
				// match each file against an expected teststring
				foreach ( $teststrings as $fileEnding  => $teststring ) {
					if ( substr( $filename, -strlen( $teststring ) ) === $teststring ) {
						$info = stat( "$dirname/$subdir/$filename" );
						$subDump[$fileEnding] = array(
							'timestamp' => gmdate( 'Y-m-d', $info['mtime'] ),
							'byteSize' => $info['size'],
							'filename' => $filename
						);
					}
				}
			}
			// if files found then add to dumps
			if ( count( $subDump ) > 0 ) {
				$dumps[$subdir] = $subDump;
			}
		}
	}

	return $dumps;
}

/**
 * Scan dump directory for dump files (if any) and
 * create dcatap.rdf in the same directory
 *
 * @param array command line options to override defaults
 */
function run( $options ) {
	// Load config variables and i18n a data blob
	if ( !isset( $options['config'] ) ) {
		$options['config'] = 'config.json';
	}
	if ( !is_file( $options['config'] ) ) {
		exit( $options['config'] . " does not seem to exist" );
	}
	$data = makeDataBlob( $options['config'] );

	// Load directories from config/options and test for existence
	if ( !isset( $options['dumpDir'] ) ) {
		$options['dumpDir'] = $data['config']['directory'];
	}
	if ( !is_dir( $options['dumpDir'] ) ) {
		exit( $options['dumpDir'] . " is not a valid directory" );
	}
	if ( !isset( $options['outputDir'] ) ) {
		$options['outputDir'] = $data['config']['directory'];
	}
	if ( !is_dir( $options['outputDir'] ) ) {
		exit( $options['outputDir'] . " is not a valid directory" );
	}

	// add dump data to data blob
	$data['dumps'] = scanDump( $options['dumpDir'], $data );

	// create xml string from data blob
	$xml = outputXml( $data );

	file_put_contents( $options['outputDir'] . "/dcatap.rdf", $xml );
}

// run from command-line with options
// Load options
$longopts  = array(
	"config::",     // Path to the config.json, default: config.json
	"dumpDir::",    // Path to the directory containing entity dumps, default: set in config
	"outputDir::"   // Path where dcat.rdf should be outputted, default: same as dumpDir
);
$options = getopt( '', $longopts );
run( $options );
?>
