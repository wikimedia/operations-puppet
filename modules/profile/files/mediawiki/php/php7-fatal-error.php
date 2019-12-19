<?php
# This file is managed by Puppet.

$err = error_get_last();

// What can $err look like?
//
// == Fatal during main stack ==
//
// Last confirmed: December 2019 (PHP 7.2.24).
//
// When a fatal exception happens during the main stack,
// then $err is populated with the properties of the Exception
// object. $err has no trace field, but the stack is still intact
// in this scenario, so we can get it the normal way.
//
// file: /srv/mediawiki/php-.../vendor/guzzlehttp/psr7/src/Stream.php
// line: 73
// message: Maximum execution time of 180 seconds exceeded
// --
// debug_backtrace:
//     #1 /srv/mediawiki/php-/extensions/.../CheckConstraintsJob.php(74): CheckConstraintsJob->checkConstraints()
//     #2 /srv/mediawiki/php-/JobExecutor.php(70): CheckConstraintsJob->run()
//     #3 /srv/mediawiki/rpc/RunSingleJob.php(76): JobExecutor->execute()
//
// == Fatal during shutdown ==
//
// Last confirmed: December 2019 (PHP 7.2.24).
//
// When a fatal exception happens during request process shutdown.
// This is post-send and after the main call stack has unwound.
// This new stack stack will originate from one of the __destruct() methods,
// or from a register_shutdown_function callback.
//
// For this scenario, PHP does not expose its new stack through normal means,
// ie. debug_backtrace, or '(new Exception)->getTrace()'. Instead, it is exposed
// through the $err['message'] field.
//
// file: /srv/mediawiki/wmf-config/set-time-limit.php
// line: 39
// message: |
//     PHP Fatal error:  Uncaught WMFTimeoutException: the execution time limit of 60 seconds was exceeded in /srv/mediawiki/wmf-config/set-time-limit.php:39
//     Stack trace:
//     #0 /srv/mediawiki/php-/includes/parser/Parser.php(414): {closure}(1)
//     #1 [internal function]: Parser->__destruct()
//     #2 {main}
//       thrown in /srv/mediawiki/wmf-config/set-time-limit.php on line 39
//
$messageParts = explode( "\nStack trace:\n", $err['message'], 2 );
$message = $messageParts[0];
$trace = $messageParts[1] ?? '';
unset( $messageParts );

// Obtain a trace
if ( $trace === '' ) {
	$traceData = debug_backtrace( DEBUG_BACKTRACE_IGNORE_ARGS, 500 );
	// Based on mediawiki-core: MWExceptionHandler::prettyPrintTrace()
	foreach ( $traceData as $level => $frame ) {
		if ( isset( $frame['file'] ) && isset( $frame['line'] ) ) {
			$trace .= "#{$level} {$frame['file']}({$frame['line']}): ";
		} else {
			$trace .= "#{$level} [internal function]: ";
		}
		if ( isset( $frame['class'] ) && isset( $frame['type'] ) && isset( $frame['function'] ) ) {
			$trace .= $frame['class'] . $frame['type'] . $frame['function'];
		} elseif ( isset( $frame['function'] ) ) {
			$trace .= $frame['function'];
		} else {
			$trace .= 'NO_FUNCTION_GIVEN';
		}
		$trace .= "()\n";
	}
	unset( $traceData, $level, $frame );
}

// If the output has already been flushed, it may be unsafe to append an error message.
if ( !headers_sent() ) {
	header( 'HTTP/1.1 500 Internal Server Error' );

?>
<!DOCTYPE html>
<html lang="en" dir="ltr">
<meta charset="utf-8">
<title>Wikimedia Error</title>
<style>
* { margin: 0; padding: 0; }
body { background: #fff; font: 15px/1.6 sans-serif; color: #333; }
.content { margin: 7% auto 0; padding: 2em 1em 1em; max-width: 640px; }
.footer { clear: both; margin-top: 14%; border-top: 1px solid #e5e5e5; background: #f9f9f9; padding: 2em 0; font-size: 0.8em; text-align: center; }
img { float: left; margin: 0 2em 2em 0; }
a img { border: 0; }
h1 { margin-top: 1em; font-size: 1.2em; }
p { margin: 0.7em 0 1em 0; }
a { color: #0645ad; text-decoration: none; }
a:hover { text-decoration: underline; }
code { font-family: inherit; }
.text-muted { color: #777; }
</style>
<div class="content" role="main">
<a href="https://www.wikimedia.org"><img src="https://www.wikimedia.org/static/images/wmf.png" srcset="https://www.wikimedia.org/static/images/wmf-2x.png 2x" alt=Wikimedia width=135 height=135></a>
<h1>Error</h1>
<p>Our servers are currently under maintenance or experiencing a technical problem. Please <a href="" title="Reload this page" onclick="location.reload(false); return false">try again</a> in a few&nbsp;minutes.</p><p>See the error message at the bottom of this page for more&nbsp;information.</p>
</div>
<div class="footer">
<p>If you report this error to the Wikimedia System Administrators, please include the details below.</p>
<p class="text-muted"><code>
  PHP fatal error<?php
	echo ": <br/> " . htmlspecialchars( $message );
?>
</code></p></div>
</html>
<?php

} // !headers_sent

include __DIR__ . '/error-params.php';

if ( $statsd_host && $statsd_port ) {
	$sock = socket_create( AF_INET, SOCK_DGRAM, SOL_UDP );
	$stat = 'MediaWiki.errors.fatal:1|c';
	// Ignore errors
	@socket_sendto( $sock, $stat, strlen( $stat ), 0, $statsd_host, $statsd_port );
}

// Should match the structure of exceptions logged by MediaWiki core.
// so that it blends in with its log channel and the Logstash dashboards
// written for it.
//
// The 'type' and 'channel' are applied later via puppet://logstash/filter-syslog.conf.
$info = [
	// Match mediawiki/core: MWExceptionHandler
	'exception' => [
		'message' => $message,
		'file' => "{$err['file']}:{$err['line']}",
		'trace' => $trace ?: '{unknown}',
	],
	'caught_by' => '/etc/php/php7-fatal-error.php (via wmerrors)',
	// Match wmf-config: logging.php
	'phpversion' => PHP_VERSION,
];
// Match mediawiki/core: MediaWiki\Logger\Monolog\WikiProcessor
if ( isset( $_SERVER['UNIQUE_ID'] ) ) {
	$info['reqId'] = $_SERVER['UNIQUE_ID'];
}
// Match Monolog\Processor\WebProcessor
// https://github.com/Seldaek/monolog/blob/2.0.0/src/Monolog/Processor/WebProcessor.php#L33
if ( isset( $_SERVER['REQUEST_URI'] ) ) {
	$info['url'] = $_SERVER['REQUEST_URI'];
}
if ( isset( $_SERVER['REMOTE_ADDR'] ) ) {
	$info['ip'] = $_SERVER['REMOTE_ADDR'];
}
if ( isset( $_SERVER['REQUEST_METHOD'] ) ) {
	$info['http_method'] = $_SERVER['REQUEST_METHOD'];
}
if ( isset( $_SERVER['SERVER_NAME'] ) ) {
	$info['server'] = $_SERVER['SERVER_NAME'];
}

$syslogMessage = '@cee: ' . json_encode( $info,  JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE );
$maxLength = 32765;
$overflow = strlen( $syslogMessage ) - $maxLength;
if ( $overflow > 0 ) {
	// Too big. Just truncate the trace if possible.
	if ( strlen( $syslogMessage ) - strlen( $trace ) < $maxLength ) {
		$info['exception']['trace'] = substr( $trace, 0, -$overflow );
	} else {
		// Truncate everything
		array_walk_recursive( $info, function ( &$item ) use ( $maxLength ) {
			$item = substr( $item, 0, $maxLength / 20 );
		} );
	}
	$syslogMessage = '@cee: ' . json_encode( $info, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE );
}

syslog( LOG_ERR, $syslogMessage );

