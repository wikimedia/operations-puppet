<?php
## HTTP response status codes
## http://tools.ietf.org/html/rfc2616
## http://en.wikipedia.org/wiki/List_of_HTTP_status_codes

$http_status[0]="Unknown";
# 1xx Informational
$http_status[100]="Continue";
$http_status[101]="Switching Protocols";
$http_status[102]="Processing (WebDAV)";

# 2xx Success
$http_status[200]="OK";
$http_status[201]="Created";
$http_status[202]="Accepted";
$http_status[203]="Non-Authoritative Information (since HTTP/1.1)";
$http_status[204]="No Content";
$http_status[205]="Reset Content";
$http_status[206]="Partial Content";
$http_status[207]="Multi-Status (WebDAV)";

# 3xx Redirection
$http_status[300]="Multiple Choices";
$http_status[301]="Moved Permanently";
$http_status[302]="Found";
$http_status[303]="See Other (since HTTP/1.1)";
$http_status[304]="Not Modified";
$http_status[305]="Use Proxy (since HTTP/1.1)";
$http_status[306]="Switch Proxy";
$http_status[307]="Temporary Redirect (since HTTP/1.1)";

# 4xx Client Error
$http_status[400]="Bad Request";
$http_status[401]="Unauthorized";
$http_status[402]="Payment Required";
$http_status[403]="Forbidden";
$http_status[404]="Not Found";
$http_status[405]="Method Not Allowed";
$http_status[406]="Not Acceptable";
$http_status[407]="Proxy Authentication Required";
$http_status[408]="Request Timeout";
$http_status[409]="Conflict";
$http_status[410]="Gone";
$http_status[411]="Length Required";
$http_status[412]="Precondition Failed";
$http_status[413]="Request Entity Too Large";
$http_status[414]="Request-URI Too Long";
$http_status[415]="Unsupported Media Type";
$http_status[416]="Requested Range Not Satisfiable";
$http_status[417]="Expectation Failed";
$http_status[422]="Unprocessable Entity (WebDAV)";
$http_status[423]="Locked (WebDAV)";
$http_status[424]="Failed Dependency (WebDAV)";
$http_status[425]="Unordered Collection (WebDAV)";
$http_status[426]="Upgrade Required (client should switch to TLS/1.0)";
$http_status[449]="Retry With (Microsoft extension)";

# 5xx Server Error
$http_status[500]="Internal Server Error";
$http_status[501]="Not Implemented";
$http_status[502]="Bad Gateway";
$http_status[503]="Service Unavailable";
$http_status[504]="Gateway Timeout";
$http_status[505]="HTTP Version Not Supported";
$http_status[507]="Insufficient Storage (WebDAV)";
$http_status[509]="Bandwidth Limit Exceeded";

# 9xx Self Defined for Wikistats

$http_status[994]="200 but MySQL database error detected";
$http_status[995]="n/a - used lynx";
$http_status[996]="n/a - used w3m";
$http_status[997]="200 but failed parsing";
$http_status[998]="200 but empty buffer";
$http_status[999]="Outdated. Timestamp was older 14 days.";

?>

