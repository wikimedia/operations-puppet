<?php
/*

Admin cli interface for php-fpm. It supports a /metrics endpoint where we expose data
in a format prometheus likes.
*/
require('lib.php');

$usage = <<<'EOD'
Supported urls:

  /metrics         Metrics about APCu and OPcache usage
  /apcu-info       Show basic APCu stats
  /apcu-meta       Dump meta information for all objects in APCu to /tmp/apcu_dump_meta
  /apcu-free       Clear all data from APCu
  /apcu-frag       APCu fragmentation percentage
  /opcache-info    Show basic opcache stats
  /opcache-meta    Dump meta information for all objects in opcache to /tmp/opcache_dump_meta
  /opcache-free    Clear all data from opcache
  /ini-get         Get the ini values for the running daemon. Add a key parameter if you want just one.

EOD;

ob_start();

switch ($_SERVER['SCRIPT_NAME']) {
	case '/metrics':
		# This will make requests to the other php admin ports for /local-metrics, and combine them all
		# in a single output.
		show_all_prometheus_metrics();
		break;
	case '/local-metrics':
		show_prometheus_metrics();
		break;
	case '/apcu-info':
		show_apcu_info();
		break;
	case '/apcu-meta':
		dump_apcu_full();
		break;
	case '/apcu-free':
		// this is an administrative action
		clear_apcu();
		break;
	case '/apcu-frag':
		show_apcu_frag();
		break;
	case '/opcache-info':
		show_opcache_info();
		break;
	case '/opcache-meta':
		dump_opcache_meta();
		break;
	case '/opcache-free':
		clear_opcache();
		break;
	case '/ini-get':
		ini_value();
		break;
	default:
		header("Content-Type: text/plain");
		echo $usage;
}

ob_flush();
