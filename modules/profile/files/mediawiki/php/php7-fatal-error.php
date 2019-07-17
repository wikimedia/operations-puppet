<?php
# This file is managed by Puppet.

$err = error_get_last();
$message = $err['message'];
$message = preg_replace( "/^.*?exception '.*?' with message '(.*?)'.*$/im", '\1', $message );

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

ob_start();
debug_print_backtrace( DEBUG_BACKTRACE_IGNORE_ARGS, 500 );
$trace = ob_get_clean();

// Remove the first line which just says "#0 unknown"
$newlinePos = strpos( $trace, "\n" );
if ( $newlinePos !== false && $newlinePos < strlen( $trace ) - 1 ) {
	$trace = substr( $trace, $newlinePos + 1 );
}

$info = [
	'exception' => [
		'message' => $message,
		'file' => "{$err['file']}:{$err['line']}",
		'trace' => $trace,
	],
	'phpversion' => PHP_VERSION,
];
if ( isset( $_SERVER['UNIQUE_ID'] ) ) {
	$info['reqId'] = $_SERVER['UNIQUE_ID'];
}
if ( isset( $_SERVER['REQUEST_METHOD'] ) ) {
	$info['http_method'] = $_SERVER['REQUEST_METHOD'];
}
if ( isset( $_SERVER['HTTP_HOST'] ) ) {
	$info['server'] = $_SERVER['HTTP_HOST'];
}
if ( isset( $_SERVER['REQUEST_URI'] ) ) {
	$info['url'] = $_SERVER['REQUEST_URI'];
}
if ( isset( $_SERVER['REMOTE_ADDR'] ) ) {
	$info['ip'] = $_SERVER['REMOTE_ADDR'];
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

