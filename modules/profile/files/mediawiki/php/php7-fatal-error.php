<?php
# This file is managed by Puppet.

$err = error_get_last();

// What can $err look like?
//
// == Unrecoverable ==
//
// Last confirmed: February 2021 (PHP 7.2.31).
//
// When an unrecoverable error happens, the stack is left intact when
// the php-wmerrors extension executes this error page, so we can obtain
// the stack manually from debug_backtrace() still.
//
// For example:
//
//   $err['file'] => /srv/mediawiki/php-.../includes/Example.php
//   $err['line'] => 39
//   $err['message'] => Allowed memory size of 698351616 bytes exhausted
//   debug_backtrace =>
//     #1 /srv/mediawiki/php-.../.../Wikibase/ChangeNotificationJob.php(120): array_map()
//     #2 /srv/mediawiki/php-.../JobExecutor.php(70): ChangeNotificationJob->run()
//     #3 /srv/mediawiki/rpc/RunSingleJob.php(76): JobExecutor->execute()
//
// Reproduce:
//
//   Use w/fatal-error.php?action=oom
//   The source can be anything (main, postsend, shutdown etc.) as in all cases it will
//   be handled by php-wmerrors. Note that in most cases, unrecoverable errors are also
//   observed by MediaWiki's MWExceptionHandler as well and thus reported twice to
//   Logstash.
//
// == Throwable ==
//
// Last confirmed: February 2021 (PHP 7.2.31).
//
// It is rare for a fatal error to be rendered for an Exception or other runtime
// Throwable, as these can and should almost always be handled by the MediaWiki
// application instead. However, it can sometimes happen from a `__destruct`
// or `register_shutdown_function` callback.
//
// In this scenario, Zend PHP seems to have unwound its call stack, i.e. as
// seen from debug_backtrace or '(new Exception)->getTrace()'. But, the trace is
// given to us by Zend PHP as part of the $err['message'] string.
//
// For example:
//
//   $err['file'] => /srv/mediawiki/Example.php
//   $err['line'] => 140
//   $err['message'] =>
//     Uncaught Exception: Foo in /srv/mediawiki/Example.php:140
//
//     Stack trace:
//     #1 /srv/mediawiki/Example.php(80): Example->checkFoo()
//     #2 /srv/mediawiki/php-/JobExecutor.php(70): Example->run()
//     #3 /srv/mediawiki/rpc/RunSingleJob.php(76): JobExecutor->execute()
//
// Reproduce:
//
//   Use w/fatal-error.php?action=exception&source=destruct or source=shutdown.
//
//   The source needs to be late as for earlier stages MediaWiki can and will
//   report the error on its own, and then signal to PHP that it does not need
//   further handling and thus does not make its way here.
//
$messageParts = explode( "\nStack trace:\n", $err['message'], 2 );
$message = $messageParts[0];
$trace = $messageParts[1] ?? '';
unset( $messageParts );
$messageLong = $message;
$messageNorm = $message;

if ( $trace === '' ) {
	// No trace, assume "Unrecoverable" error.
	// This is the most common use of this script.
	$messageLong = "PHP Fatal error: {$message} in {$err['file']}:{$err['line']}";
	$messageNorm = $message . ' in ' . basename( $err['file'] );

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

// Match mediawiki/core: WebRequest::getRequestId
$reqId = $_SERVER['HTTP_X_REQUEST_ID'] ?? $_SERVER['UNIQUE_ID'] ?? 'unknown';

// If the output has already been flushed, it may be unsafe to append an error message.
if ( !headers_sent() ) {
	header( 'HTTP/1.1 500 Internal Server Error' );

	// Match mediawiki/core: HeaderCallback::callback
	// This allows WikimediaDebug browser extension to link to relevant error logs.
	header( 'X-Request-Id: ' . $reqId );

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
@media (prefers-color-scheme: dark) {
  a { color: #9e9eff; }
  body { background: transparent; color: #ddd; }
  .footer { border-top: 1px solid #444; background: #060606; }
  #logo { filter: invert(1) hue-rotate(180deg); }
  .text-muted { color: #888; }
}
</style>
<meta name="color-scheme" content="light dark">
<div class="content" role="main">
<a href="https://www.wikimedia.org"><img id="logo" src="https://www.wikimedia.org/static/images/wmf.png" srcset="https://www.wikimedia.org/static/images/wmf-2x.png 2x" alt=Wikimedia width=135 height=135></a>
<h1>Error</h1>
<p>Our servers are currently under maintenance or experiencing a technical problem. Please <a href="" title="Reload this page" onclick="location.reload(false); return false">try again</a> in a few&nbsp;minutes.</p><p>See the error message at the bottom of this page for more&nbsp;information.</p>
</div>
<div class="footer">
<p>If you report this error to the Wikimedia System Administrators, please include the details below.</p>
<p class="text-muted"><code>
  Request ID: <?php echo htmlspecialchars( $reqId ); ?><br/>
  <?php echo htmlspecialchars( $message ); ?>
</code></p></div>
</html>
<?php

} // !headers_sent

// This should array match the structure of exceptions logged by MediaWiki core.
// so that it blends in with its log channel and the Logstash dashboards
// written for it.
$info = [
	// Match mediawiki/core: MWExceptionHandler
	'channel' => 'exception',
	// Match mediawiki/core: MWExceptionHandler
	'message' => '[' . $reqId . '] ' . $messageLong,
	'exception' => [
		'message' => $message,
		'file' => "{$err['file']}:{$err['line']}",
		'trace' => $trace ?: 'unknown',
	],
	'caught_by' => 'php-wmerrors',
	// Match mediawiki/core: MediaWiki\Logger\Monolog\WikiProcessor
	'reqId' => $reqId,
	// Match wmf-config: logging.php
	'phpversion' => PHP_VERSION,
	// Match wmf-config: logging.php
	'servergroup' => $_SERVER['SERVERGROUP'] ?? '',
	// Match wmf-config: logging.php
	// Match mediawiki/core: CeeFormatter
	'type' => 'mediawiki',
	'normalized_message' => $messageNorm,
];
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

$mwversionPrefix = '/srv/mediawiki/php-';
if ( strpos( $err['file'], $mwversionPrefix ) === 0 ) {
	// Extract "1.37.0-wmf.23" from "/srv/mediawiki/php-1.37.0-wmf.23/foo/bar.php:123"
	$mwversionRemain = substr( $err['file'], strlen( $mwversionPrefix ) );
	// Match mediawiki/core: MediaWiki\Logger\Monolog\WikiProcessor
	$info['mwversion'] = explode( '/', $mwversionRemain, 2 )[0];
}

$syslogMessage = '@cee: ' . json_encode( $info,  JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE );
$maxLength = 32765;
$overflow = strlen( $syslogMessage ) - $maxLength;
if ( $overflow > 0 ) {
	// Too big. Just truncate the trace if possible.
	if ( strlen( $syslogMessage ) - strlen( $trace ) < $maxLength ) {
		$info['exception']['trace'] = substr( $trace, 0, -$overflow );
	} else {
		// Truncate everything to no more than ~1600 chars
		array_walk_recursive( $info, function ( &$item ) use ( $maxLength ) {
			$item = substr( $item, 0, $maxLength / 20 );
		} );
	}
	$syslogMessage = '@cee: ' . json_encode( $info, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE );
}

if ( strpos( ( $_SERVER['SERVERGROUP'] ?? null ), 'kube-' ) === 0 ) {
	// On kubernetes, send to rsyslog port directly, same as MediaWiki does.
	$sock = socket_create( AF_INET, SOCK_DGRAM, SOL_UDP );
	// Match string format of MediaWiki\Logger\Monolog\SyslogHandler
	// Match appname, hostname, and socket destination from wmf-config/logging.php.
	// priority 11 = 3 (LOG_ERR severity) + 8 (LOG_USER facility).
	$syslogMessage = sprintf( "<11>%s %s mediawiki: %s",
		date( 'M j H:i:s' ),
		php_uname( 'n' ),
		$syslogMessage
	);
	// Match destination of wmf-config/logging.php
	@socket_sendto( $sock, $syslogMessage, strlen( $syslogMessage ), 0, '127.0.0.1', 10514 );
} else {
	syslog( LOG_ERR, $syslogMessage );
}

include __DIR__ . '/error-params.php';

if ( $statsd_host && $statsd_port ) {
	$sock = socket_create( AF_INET, SOCK_DGRAM, SOL_UDP );
	$stat = 'MediaWiki.errors.fatal:1|c';
	// Ignore errors
	@socket_sendto( $sock, $stat, strlen( $stat ), 0, $statsd_host, $statsd_port );
}

if ( $dogstatsd_host && $dogstatsd_port ) {
	$sock = socket_create( AF_INET, SOCK_DGRAM, SOL_UDP );
	$stat = 'mediawiki.fatal_errors_total:1|c';
	// Ignore errors
	@socket_sendto( $sock, $stat, strlen( $stat ), 0, $dogstatsd_host, $dogstatsd_port );
}
