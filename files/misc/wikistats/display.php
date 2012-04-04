<?php
# wikistats - display html tables
header('Last-Modified: '.getlastmod());
header('Content-type: text/html; charset=utf-8');

$project = substr($_GET['t'], 0, 2);

switch ($project) {
	case "wp":
		$project_name="Wikipedias";
		$domain="wikipedia.org";
		$db_table="wikipedias";
	break;
	case "wb":
		$project_name="Wikibooks";
		$domain="wikibooks.org";
		$db_table="wikibooks";
	break;
	case "mw":
		$project_name="Mediawikis";
		$domain="na";
		$db_table="mediawikis";
	break;
	case "wn":
		$project_name="Wikinews";
		$domain="wikinews.org";
		$db_table="wikinews";
	break;
	case "wt":
		$project_name="Wiktionaries";
		$domain="wiktionary.org";
		$db_table="wiktionaries";
	break;
	case "wq":
		$project_name="Wikiquotes";
		$domain="wikiquote.org";
		$db_table="wikiquotes";
	break;
	case "ws":
		$project_name="Wikisources";
		$domain="wikisource.org";
		$db_table="wikisources";
	break;
	case "wv":
		$project_name="Wikiversities";
		$domain="wikiversity.org";
		$db_table="wikiversity";
	break;
	case "wx":
		$project_name="Wikimedia Special Projects";
		$domain="wikimedia.org";
		$db_table="wmspecials";
	break;
	case "un":
		$project_name="Uncyclo(pm)edias";
		$domain="na";
		$db_table="uncyclomedia";
	break;
	case "mt":
		$project_name="Metapedias";
		$domain="metapedia.org";
		$db_table="metapedias";
	break;
	case "os":
		$project_name="OpenSUSE wikis";
		$domain="opensuse.org";
		$db_table="opensuse";
	break;
	case "gt":
		$project_name="Gentoo wikis";
		$domain="gentoo-wiki.com";
		$db_table="gentoo";
	break;
	case "an":
		$project_name="Anarchopedias";
		$domain="anarchopedia.org";
		$db_table="anarchopedias";
	break;
	case "wf":
		$project_name="Wikifur wikis";
		$domain="wikifur.org";
		$db_table="wikifur";
	break;

	case "ne":
		$project_name="Neoseeker wikis";
		$domain="neoseeker.com";
		$db_table="neoseeker";
	break;
	case "et":
		$project_name="EditThis wikis";
		$domain="editthis.info";
		$db_table="editthis";
	break;
	case "sw":
		$project_name="Shoutwikis";
		$domain="shoutwiki.com";
		$db_table="shoutwiki";
	break;
	case "sc":
		$project_name="Scoutwikis";
		$domain="scoutwiki.org";
		$db_table="scoutwiki";
	break;
	case "wr":
		$project_name="Wikitravel wikis";
		$domain="wikitravel.org";
		$db_table="wikitravel";
	break;
	case "si":
		$project_name="Wiki-site wikis";
		$domain="wiki-site.com";
		$db_table="wikisite";
	break;
	case "wi":
		$project_name="Wikia wikis";
		$domain="wikia.com";
		$db_table="wikia";
	break;
	case "re":
		$project_name="Referata wikis";
		$domain="referata.com";
		$db_table="referata";
	break;
	case "pa":
		$project_name="Pardus wikis";
		$domain="pardus-wiki.org";
		$db_table="pardus";
	break;
	case "ro":
		$project_name="Rodovid wikis";
		$domain="rodovid.org";
		$db_table="rodovid";
	break;
	case "wk":
		$project_name="wikkii wikis";		
		$domain="wikkii.com";
		$db_table="wikkii";
	break;
default:	

	$project_name="invalid";
	$domain="localhost";
	$db_table="";

print <<<FNORD
	<html><p>invalid project key or still needs to be created. </p><ul>
	<li><a href="display.php?t=wp">wp</a> (wikipedias)</li><a href="display.php?t=wt">wt</a> (wiktionaries)</li><li><a href="display.php?t=ws">ws</a> (wikisources)</li>
	<li><a href="display.php?t=mw">mw</a> (mediawikis)</li><li><a href="display.php?t=wi">wi</a> (wikia)</li><li><a href="display.php?t=wx">wx</a> (wmspecials)</li>
	<li><a href="display.php?t=un">un</a> (uncyclomedias)</li><li><a href="display.php?t=wn">wn</a> (wikinews)</li><li><a href="display.php?t=mt">mt</a> (metapedias)</li>
	<li><a href="display.php?t=wb">wb</a> (wikibooks)</li><li><a href="display.php?t=wq">wq</a> (wikiquotes)</li><li><a href="display.php?t=et">et</a> (editthis)</li>
	<li><a href="display.php?t=si">si</a> (wikisite)</li><li><a href="display.php?t=sw">sw</a> (shoutwiki)</li><li><a href="display.php?t=wr">wr</a> (wikitravel)</li>
	<li><a href="display.php?t=ne">ne</a> (neoseeker)</li><li><a href="display.php?t=wv">wv</a> (wikiversity)</li><li><a href="display.php?t=sc">sc</a> (scoutwiki)</li>
	<li><a href="display.php?t=wf">wf</a> (wikifur)</li><li><a href="display.php?t=an">an</a> (anarchopedias)</li><li><a href="display.php?t=gt">gt</a> (gentoo)</li> 
	<li><a href="display.php?t=os">os</a> (opensuse)</li><li><a href="display.php?t=re">re</a> (referata)</li><li><a href="display.php?t=pa">pa</a> (pardus)</li>
	</ul></html>	
FNORD;
exit;
}

$listname="List of ${project_name}";
$wikioutput="${db_table}_wiki.php";
$wikipage="http://meta.wikimedia.org/wiki/${db_table}";

require_once("config.php");
require_once("./includes/functions.php");
require_once("./includes/http_status_codes.php");

mysql_connect("$dbhost", "$dbname", "$dbpass") or die(mysql_error());
include("./includes/sortswitch.php");
mysql_select_db("$dbdatabase") or die(mysql_error());
$query = "select *,good/total as ratio,TIMESTAMPDIFF(MINUTE, ts, now()) as oldness from ${db_table} order by $sort limit 500";
$result = mysql_query("$query") or die(mysql_error()); 
# echo "Sent query: '$query'.<br /><br />";

echo "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">
<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"en\" xml:lang=\"en\">";
echo "<head><title>WikiStats - $listname</title>\n<link href=\"./css/wikistats_css.php\" rel=\"stylesheet\" type=\"text/css\" /></head>\n\n<body>\n";

if (isset($_GET['th']) && is_numeric($_GET['th']) && $_GET['th'] >= 0 && $_GET['th'] < 10000000) {
	$threshold=$_GET['th'];
	$threshold=mysql_real_escape_string($threshold);
} elseif (isset($_COOKIE['wikistats_prefs'])) {
	$cookiedata=explode("-",$_COOKIE['wikistats_prefs']);
	$name=$cookiedata[0];
	$threshold=$cookiedata[1];
	$limit=$cookiedata[2];
	if ($limit=""){
		$limit=0;
	}
	$color['back']=$cookiedata[2];
	$color['table']=$cookiedata[3];
	$color['text']=$cookiedata[4];
} else {
	$threshold=0;
	$color['back']="cccccc";
	$color['table']="eeeeee";
	$color['text']="000000";
}

if (isset($_GET['lines']) && is_numeric($_GET['lines']) && $_GET['lines'] > 0 && $_GET['lines'] < 10001) {
	$limit=$_GET['lines'];
	$limit=mysql_real_escape_string($limit);
} elseif (isset($_COOKIE['wikistats_prefs'])) {
	$cookiedata=explode("-",$_COOKIE['wikistats_prefs']);
	$name=$cookiedata[0];
	$limit=$cookiedata[2];
} else {
	$limit="200";
}

echo "<div id=\"main\" style=\"float:left;width:90%;\"><table border=\"0\"><tr>
<th class=\"head\" colspan=\"10\">$listname</th></tr><tr>
<th class=\"sub\">&#8470;</th>";


if (in_array($db_table, $tables_with_language_columns)) {
	echo "<th class=\"sub\">Language (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=lang_asc\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=lang_desc\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>
<th class=\"sub\">Language (local) (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=loclang_asc\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=loclang_desc\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>
<th class=\"sub\">Wiki (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=prefix_asc\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=prefix_desc\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>";
} elseif ($project == "wx") {
	echo "<th class=\"sub\">Language (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=lang_asc\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=lang_desc\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>
<th class=\"sub\">Description (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=loclang_asc\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=loclang_desc\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>
<th class=\"sub\">Wiki (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=prefix_asc\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=prefix_desc\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>";
} else {
	echo "<th class=\"sub\">Name (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=name_asc\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=name_desc\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>";
}

echo "
<th class=\"sub\">Good (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=good_asc\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=good_desc\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>
<th class=\"sub\">Total (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=total_asc\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=total_desc\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>
<th class=\"sub\">Edits (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=edits_asc\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=edits_desc\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>
<th class=\"sub\">Admins (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=admins_asc\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=admins_desc\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>
<th class=\"sub\">Users (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=users_asc\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=users_desc\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>
<th class=\"sub\">Active Users (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=ausers_asc\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=ausers_desc\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>
<th class=\"sub\">Images (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=images_asc\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=images_desc\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>
<th class=\"sub\">Stub Ratio (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=ratio_asc\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=ratio_desc\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>";

#FIXME
#if ($_SERVER['PHP_SELF']=="/wikistats/wikipedias_html.php") { 
#echo "<th class=\"sub\">Depth (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=depth_asc\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=depth_desc\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>";
#}

echo "<th class=\"sub\">Version (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=version_asc&amp;th=$threshold&amp;lines=$limit\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=version_desc&amp;th=$threshold&amp;lines=$limit\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>
<th class=\"sub\">http (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project?sort=amp;sort=http_asc&amp;th=$threshold&amp;lines=$limit\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project?sort=amp;sort=http_desc&amp;th=$threshold&amp;lines=$limit\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>	
<th class=\"sub\" align=\"right\">Last update (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=ts_asc\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?t=$project&amp;sort=ts_desc\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th></tr>
";


$count=1;
$count=1;
$gtotal=0;
$ggood=0;
$gedits=0;
$gadmins=0;
$gusers=0;
$gimages=0;

while($row = mysql_fetch_array( $result )) {
	$gtotal=$gtotal+$row['total'];
	$ggood=$ggood+$row['good'];
	$gedits=$gedits+$row['edits'];
	$gadmins=$gadmins+$row['admins'];
	$gusers=$gusers+$row['users'];
	$gimages=$gimages+$row['images'];
	$vurl="http://".$row['prefix'].".$domain/wiki/Special:Version";

	if (isset($row['name'])) {
		$wikiname=htmlspecialchars($row['name']);
	} else {
		$wikiname=htmlspecialchars($row['prefix']);
	}

	echo "<tr><td class=\"number\">$count</td>";

	if (in_array($db_table, $tables_with_statsurl)) {
		$domain=explode(":",$row['statsurl']);
		$domain=$domain[1];
	}

	if (in_array($db_table, $tables_with_language_columns)) {
		echo "
		<td class=\"text\"><a href=\"http://en.wikipedia.org/wiki/".$row['lang']."_language\">".$row['lang']."</a></td>
		<td class=\"text\"><a href=\"http://en.wikipedia.org/wiki/".$row['lang']."_language\">".$row['loclang']."</a></td>
		<td class=\"text\"><a href=\"http://".$row['prefix'].".${domain}/wiki/\">".$row['prefix']."</a></td>";

	} elseif ($project == "wx") {
		echo "
		<td class=\"text\"><a href=\"http://en.wikipedia.org/wiki/".$row['lang']."_language\">".$row['lang']."</a></td>
		<td class=\"text\">".$row['description']."</td>
		<td class=\"text\"><a href=\"http://".$row['prefix'].".${domain}/wiki/\">".$row['prefix']."</a></td>";

	} elseif ($project == "mw") {

		if ($row['textstats']=="8") {
			$wikiurl=explode("api.php",$row['statsurl']);
			$vurl=$wikiurl[0]."index.php?title=Special:Version";
			$wikiurl=$wikiurl[0]."index.php?title=Special";
			$statsurl=$row['statsurl'];
			$mainurl=explode("api.php",$wikiurl);
			$mainurl=explode("index.php",$mainurl[0]);
			$mainurl=$mainurl[0];
		} else {
			$wikiurl=explode(":",$row['statsurl']);
			$wikiurl=htmlspecialchars($wikiurl[1]);
			$mainurl=explode("Special",$wikiurl);
			$mainurl=explode("title=",$mainurl[0]);
			$mainurl=$mainurl[0];
		}

		echo "<td class=\"text\"><a href=\"${mainurl}\">".${wikiname}."</a></td>";
	} else {
	echo "<td class=\"text\"><a href=\"http://".$row['prefix'].".${domain}/wiki/\">".${wikiname}."</a></td>";
	}
	if (isset($row['http'])) {
		$statuscode=$row['http'];
	} else {
		$statuscode="999";
	}


	# Color http status
	 if ($statuscode=="200" or $statuscode=="302") {
		 $statuscolor="#AAEEAA";
	 } elseif ($statuscode=="0") {
		 $statuscolor="#AAAAAA";
	 } elseif (substr($statuscode, 0, 1)=="4" or substr($statuscode, 0, 1)=="5") {
		 $statuscolor="#CC2222";
	 } elseif (substr($statuscode, 0, 1)=="9") {
		 $statuscolor="#FFCCCC";
	 } else {
		 $statuscolor="#FF6666";
	 }

	# Color old timestamps
	if ($row['oldness'] > 2879){
		$tscolor="#CC2222";
	} elseif ($row['oldness'] > 1439){
		$tscolor="#FF6666";
	} else {
		$tscolor="#AAEEAA";
	}

	echo "
	<td class=\"number\"><a href=\"http://".$row['prefix'].".${domain}/w/api.php?action=query&amp;meta=siteinfo&amp;siprop=statistics\">".$row['good']."</a></td>
	<td class=\"number\">".$row['total']."</td><td class=\"number\"><a href=\"http://".$row['prefix'].".${domain}/wiki/Special:Recentchanges\">".$row['edits']."</a></td>
	<td class=\"number\"><a href=\"http://".$row['prefix'].".${domain}/wiki/Special:Listadmins\">".$row['admins']."</a></td>
	<td class=\"number\"><a href=\"http://".$row['prefix'].".${domain}/wiki/Special:Listusers\">".$row['users']."</a></td>
	<td class=\"number\"><a href=\"http://".$row['prefix'].".${domain}/wiki/Special:Listusers\">".$row['activeusers']."</a></td>
	<td class=\"number\"><a href=\"http://".$row['prefix'].".${domain}/wiki/Special:Imagelist\">".$row['images']."</a></td>
	<td class=\"number\">".$row['ratio']."</td>
	<td style=\"background: ".version_color($row['version']).";\" class=\"text\"><a href=\"${vurl}\">".$row['version']."</a></td>
	<td style=\"background: ".$statuscolor.";\" class=\"number\"><div title=\"$http_status[$statuscode]\">$statuscode</div></td>
	<td style=\"background: ".$tscolor.";\" class=\"timestamp\">".$row['ts']."</td></tr>\n";

	$count++;
}

echo "</table>\n\n";
include ("./includes/grandtotal.php");
include ("./includes/footer.php");
echo "</div></body></html>";
?>
