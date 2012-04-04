<?php
# rank.php - quick sketch , ~ 2010 by mutante for Danny_B, see below
# <Danny_B> position of such wiktionary in all wiktionaries <space> number of all wiktionaries <space> position of such wiktionary in all wmf wikis <space> number of all wmf wikis
# the second wish was for the following behavior:
# position.php?family=wiktionaries&position=42 RETURN: cs
# position.php?family=wmfwikis&position=1 RETURN: enwiki

require_once("config.php");
mysql_connect("$dbhost", "$dbname", "$dbpass") or die(mysql_error());
mysql_select_db("$dbdatabase") or die(mysql_error());
$count=1;
$arcount=0;
$lang_check="FALSE";
$languages=array();

if (isset($_GET['lang'])) {
	$lang=$_GET['lang'];
	$lang=mysql_real_escape_string($lang);
}

$query = "select prefix,lang from wikipedias where prefix is not null order by prefix asc";
$result = mysql_query("$query") or die(mysql_error());

while($row = mysql_fetch_array( $result )) {

	$languages[$arcount]=$row[prefix]." - ".$row[lang];
	$arcount++;
	if ($row[prefix]==$lang) {
		$lang_check="OK";
	} 

}

if (isset($_GET['lang']) AND $lang_check=="OK"){
	$lang=$lang;
} elseif (isset($_GET['lang']) AND $lang_check!="OK") {
	echo "This language does not exist (as a wikipedia).";
	exit(1);
} else {
	echo "<html><body><h4>This script returns the ranking of a Wikimedia foundation project when sorted by size.</h4>
	<p>usage: <pre>?family=[project family]\n\n?lang=[language]</pre></p>
	<p><form action=rank.php method='get'>project family can be one of: \n<b>w, wikt, n, b, q, s, v</b>\n\n(<a href=\"http://meta.wikimedia.org/wiki/Help:Interwiki_linking#Project_titles_and_shortcuts\">interwiki shortcuts</a>) ";
	echo "<select name=\"family\">
	<option value=\"w\">w - wikipedia</option>
	<option value=\"wikt\">wikt - wiktionary</option>
	<option value=\"n\">n - wikinews</option>
	<option value=\"b\">b - wikibooks</option>
	<option value=\"q\">q - wikiquote</option>
	<option value=\"s\">s - wikisource</option>
	<option value=\"v\">v - wikiversity</option>
	</select>";
	echo "<br /><br />language should be a language prefix that exists as a wikipedia subdomain: <select name=\"lang\">";

	foreach ($languages as $language) {
		$langprefix=explode(" - ",$language);
		$langprefix=$langprefix[0];
		echo "<option value=\"$langprefix\">$language</option>\n";
	}

	echo "</select><br /><input type='submit' value='submit' /></form><p>output:<pre>&lt;lang.project&gt; &lt;rank within project&gt; &lt;number of wikis in project&gt; &lt;global rank&gt; &lt;global number of wikis&gt;</pre>en.wikipedia 1 272 1 761</p><p>examples:<br /><a href=\"rank.php?family=w&lang=es\">?family=w&amp;lang=en</a> (Spanish Wikipedia)<br /><a href=\"rank.php?family=wikt&lang=en\">?family=wikt&amp;lang=de</a> (English Wiktionary)<br /><a href=\"rank.php?family=v&lang=ru\">?family=v&amp;lang=ru</a> (Russian Wikiversity)</b></p><p>Complete tables can be found in <a href=\"index.php\">wikistats</a>";
	exit(0);
}

if (isset($_GET['family'])) {

	switch ($_GET['family']){
		case "w":
			$table="wikipedias";
			$family="wikipedia";
		break;
		case "wikt":
			$table="wiktionaries";
			$family="wiktionary";
		break;
		case "n":
			$table="wikinews";
			$family="wikinews";
		break;
		case "b":
			$table="wikibooks";
			$family="wikibooks";
		break;
		case "q":
			$table="wikiquotes";
			$family="wikiquote";
		break;
		case "s":
			$table="wikisources";
			$family="wikisource";
		break;
		case "v":
			$table="wikiversity";
			$family="wikiversity";
		break;
		case "special":
			$table="wmspecials";
			$family="wmf";
		break;
	default:
	echo "<pre>project family does not exist.\n\nplease use one of: w, wikt, n, b, q, s, v.\n\nlike the shortcuts from http://meta.wikimedia.org/wiki/Help:Interwiki_linking";
	exit(1);
	}

	} else {
		$table="wiktionaries";
		$family="wiktionary";
}

# echo "table $table family $family \n";

$query = "select id,prefix from ${table} where prefix is not null order by good desc,total desc";
$result = mysql_query("$query") or die(mysql_error()); 
$num_rows = mysql_num_rows($result);

while($row = mysql_fetch_array( $result )) {

	if ($row[prefix]==$lang) {
		$rank_project=$count;
		$number_project=$num_rows;
	}
	
	$count++;
}

$count=1;

$query = <<<FNORD
(select prefix,good,lang,loclang,total,edits,admins,users,images,ts,'wikipedias' as type from wikipedias where prefix is not null)
 union all (select prefix,good,lang,loclang,total,edits,admins,users,images,ts,'wikisources' as type from wikisources)
 union all (select prefix,good,lang,loclang,total,edits,admins,users,images,ts,'wiktionaries' as type from wiktionaries)
 union all (select prefix,good,lang,loclang,total,edits,admins,users,images,ts,'wikiquotes' as type from wikiquotes)
 union all (select prefix,good,lang,loclang,total,edits,admins,users,images,ts,'wikibooks' as type from wikibooks)
 union all (select prefix,good,lang,loclang,total,edits,admins,users,images,ts,'wikinews' as type from wikinews)
 union all (select url,good,lang,loclang,total,edits,admins,users,images,ts,'wmspecials' as type from wmspecials)
 union all (select prefix,good,lang,loclang,total,edits,admins,users,images,ts,'wikiversity' as type from wikiversity)
 order by good desc,total desc;
FNORD;

$result = mysql_query("$query") or die(mysql_error());
$num_rows = mysql_num_rows($result);

while($row = mysql_fetch_array( $result )) {

	if ($row[prefix]==$lang AND $row[type]==$table) {
		$rank_global=$count;
		$number_global=$num_rows;
		$type=$row[type];
	}

	$count++;
}

echo "$lang.$family $rank_project $number_project $rank_global $number_global\n";

if ($rank_project==""){
	echo "\n! this language version does not seem to exist yet in this project";
}

mysql_close();
?>
