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
a { color: #0645AD; text-decoration: none; }
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
	// Guard against "Cannot modify header information - headers already sent" warning
	if ( !headers_sent() ) {
	  header( 'HTTP/1.1 500 Internal Server Error' );
	}
	$err = error_get_last() ?: [ 'message' => '(no error)' ];
	$message = $err['message'];
	# error_get_last() doesn't return a fully populated array in HHVM,
	# capture file and line manually
	if ( preg_match( '/#0\\s+(\\S+?)\\((\\d+)\\)/', $message, $matches ) ) {
	  echo ' ' . htmlspecialchars( $matches[1] ) . ' line ' . $matches[2];
	}
	$parts = explode( "\n", $message );
	$message = $parts[0];
	$message = preg_replace( "/^.*?exception '.*?' with message '(.*?)'.*$/im", '\1', $message );

	// Increment a counter.
	$sock = socket_create( AF_INET, SOCK_DGRAM, SOL_UDP );
	$stat = 'MediaWiki.errors.fatal:1|c';
	@socket_sendto( $sock, $stat, strlen( $stat ), 0, 'statsd.eqiad.wmnet', 8125 );

  ?>: <br/>
  <?php echo htmlspecialchars( $message ); ?>
</code></p></div>
</html>
