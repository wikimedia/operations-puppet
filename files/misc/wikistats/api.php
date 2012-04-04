<?php
# simple Wikistats API to output csv,ssv,xml dumps

require_once("config.php");
require_once("./includes/functions.php");

if (isset($_GET['action'])) {
	$action=strip_tags(trim(mysql_escape_string($_GET['action'])));

	switch ($action) {

		case "dump":

		$table=strip_tags(trim(mysql_escape_string($_GET['table'])));
		
		if (in_array($table,$valid_api_tables)) {

		$format=strip_tags(trim(mysql_escape_string($_GET['format'])));

			switch ($format) {
				case "csv":
				print data_dumper("$table","csv");
				exit(0);
				break;
				case "ssv":
				print data_dumper("$table","ssv");
				exit(0);
				case "xml":
				print xml_dumper("$table");
				exit(0);
				default:
				print "dump format not set or unknown. please specify a known format. f.e. &format=csv";
				exit(1);
			}
		} else {
		print "table name not set or unknown. please specify a known table. f.e. &table=wikipedias";
		exit(1);
		}

		break;

		default:
		print "unknown action. please specify a valid action. f.e. ?action=dump";
		exit (1);
		break;

	}

} else {

print <<<FNORD
<pre>
Wikistats API

current actions:

-  action=dump
-- dump csv, ssv or xml data of all tables

option 1: format (csv|ssv|xml)
option 2: table (wikipedias|wiktionaries|...)

example: api.php?action=dump&table=wikipedias&format=csv
example: api.php?action=dump&table=wikiquotes&format=ssv
example: api.php?action=dump&table=neoseeker&format=xml

</pre>
FNORD;

exit(0);
}

echo "Error. How did we get here? Exiting.";
exit(1);

?>
