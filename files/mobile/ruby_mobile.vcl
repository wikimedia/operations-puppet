# This is a basic VCL configuration file for varnish.  See the vcl(7)
# man page for details on VCL syntax and semantics.
# 
# Default backend definition.  Set this to point to your content
# server.
# 
backend default {
	.host = "127.0.0.1";
	.port = "81";
}

backend cp1043 {
	.host = "208.80.154.53";
	.port = "80";
	.probe = {
		.request =
			"GET /w/load.php HTTP/1.1"
			"Host: en.wikipedia.org"
			"User-agent: Varnish backend check"
			"Connection: close";
		.timeout = 5s;
	}
}

backend cp1044 {
	.host = "208.80.154.54";
	.port = "80";
	.probe = {
		.request =
			"GET /w/load.php HTTP/1.1"
			"Host: en.wikipedia.org"
			"User-agent: Varnish backend check"
			"Connection: close";
		.timeout = 5s;
	}
}

director mobext random {
	.retries = 2;
	{
		.backend = cp1043;
		.weight = 1;
	}
	{
		.backend = cp1044;
		.weight = 1;
	}
}
	
sub vcl_recv {
	set req.http.X-Forwarded-For = client.ip;

	if (req.request != "GET" && req.request != "HEAD" && req.request != "OPTION") {
		 /* We only deal with GET and HEAD by default */
		 return (pass);
	 }

	if (req.http.Cookie ~ "optin") { 
		set req.backend = mobext;
		return (pass);
	} else { 
		set req.backend = default;
	}

	return (lookup);
}

# 
# sub vcl_pipe {
#	 # Note that only the first request to the backend will have
#	 # X-Forwarded-For set.  If you use X-Forwarded-For and want to
#	 # have it set for all requests, make sure to have:
#	 # set bereq.http.connection = "close";
#	 # here.  It is not set by default as it might break some broken web
#	 # applications, like IIS with NTLM authentication.
#	 return (pipe);
# }
# 
# sub vcl_pass {
#	 return (pass);
# }
# 
# sub vcl_hash {
#	 hash_data(req.url);
#	 if (req.http.host) {
#		 hash_data(req.http.host);
#	 } else {
#		 hash_data(server.ip);
#	 }
#	 return (hash);
# }
# 
# sub vcl_hit {
#	 return (deliver);
# }
# 
# sub vcl_miss {
#	 return (fetch);
# }
# 
# sub vcl_fetch {
#	 if (beresp.ttl <= 0s ||
#		 beresp.http.Set-Cookie ||
#		 beresp.http.Vary == "*") {
# 		/*
# 		 * Mark as "Hit-For-Pass" for the next 2 minutes
# 		 */
# 		set beresp.ttl = 120 s;
# 		return (hit_for_pass);
#	 }
#	 return (deliver);
# }
# 
# sub vcl_deliver {
#	 return (deliver);
# }
# 
# sub vcl_error {
#	 set obj.http.Content-Type = "text/html; charset=utf-8";
#	 set obj.http.Retry-After = "5";
#	 synthetic {"
# <?xml version="1.0" encoding="utf-8"?>
# <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
#  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
# <html>
#   <head>
#	 <title>"} + obj.status + " " + obj.response + {"</title>
#   </head>
#   <body>
#	 <h1>Error "} + obj.status + " " + obj.response + {"</h1>
#	 <p>"} + obj.response + {"</p>
#	 <h3>Guru Meditation:</h3>
#	 <p>XID: "} + req.xid + {"</p>
#	 <hr>
#	 <p>Varnish cache server</p>
#   </body>
# </html>
# "};
#	 return (deliver);
# }
# 
# sub vcl_init {
# 	return (ok);
# }
# 
# sub vcl_fini {
# 	return (ok);
# }
