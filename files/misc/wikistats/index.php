<?php
header('Last-Modified: '.getlastmod());
header('Content-type: text/html; charset=utf-8');
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
<title>WikiStats - Mediawiki statistics</title>
<meta name="description" content="various statistics tables about Mediawikis, Wikihives, Wikimedia in html,csv,ssv and wikisyntax" />
<link href="./css/wikistats_css.php" rel="stylesheet" type="text/css" />
</head>
<body>
<div id="logos" style="float:left;">
<h2>
<img style="border:1;" src="./images/Wikistats-logo.png" width="135" height="133" alt="Wiki Stats" /><br />
Wikistats 2.0
</h2>
[beta]
</div>
<?php
$listname="Statistics about Mediawikis";

# config 
require_once("config.php");

# sort switches
if (isset($_GET['sort'])) {

	switch ($_GET['sort']) {
		case "name_asc":
			$sort = "name asc";
		break;
		case "name_desc":
			$sort = "name desc";
		break;
		case "good_asc":
			$sort = "ggood asc";
		break;
		case "good_desc":
			$sort = "ggood desc";
		break;
		case "total_asc":
			$sort = "gtotal asc";
		break;
		case "total_desc":
			$sort = "gtotal desc";
		break;
		case "edits_asc":
			$sort = "gedits asc";
		break;
		case "edits_desc":
			$sort = "gedits desc";
		break;
		case "admins_asc":
			$sort = "gadmins asc";
		break;
		case "admins_desc":
			$sort = "gadmins desc";
		break;
		case "users_asc":
			$sort = "gusers asc";
		break;
		case "users_desc":
			$sort = "gusers desc";
		break;
		case "images_asc":
			$sort = "gimages asc";
		break;
		case "images_desc":
			$sort = "gimages desc";
		break;
		case "numwikis_asc":
			$sort = "numwikis asc";
		break;
		case "numwikis_desc":
			$sort = "numwikis desc";
		break;
	default:
		$sort = "ggood desc,gtotal desc,gedits desc,gusers desc,gadmins desc";
	}

	} else {
		$sort = "ggood desc,gtotal desc,gedits desc,gusers desc,gadmins desc";
}

$sort=mysql_escape_string($sort);

# Get "Last Updated" timestamps
mysql_connect("$dbhost", "$dbname", "$dbpass") or die(mysql_error());
mysql_select_db("$dbdatabase") or die(mysql_error());

$listtables=array("wikipedias","wikiquotes","wikibooks","wiktionaries","wikinews","wikisources","wikia","editthis","wikitravel","mediawikis","uncyclomedia","anarchopedias","opensuse","richdex","gratiswiki","qweki","wikisite","gentoo","hyperwave","scoutwiki","wmspecials","qweki","wikiversity","wikifur","metapedias","neoseeker","shoutwiki","referata","pardus","rodovid","wikkii");

foreach ($listtables as $listtable) {
	$query="select ts,TIMESTAMPDIFF(MINUTE, ts, now()) as oldness from $listtable order by ts desc limit 1";
	$result = mysql_query("$query") or die(mysql_error());

	while($row = mysql_fetch_array( $result )) {
		$ts=$row['ts'];
		$timestamp[$listtable]=$ts;

		# Color old timestamps
		if ($row['oldness'] > 2879){
			$tscolor[$listtable]="#DD6666";
		} elseif ($row['oldness'] > 1439){
			$tscolor[$listtable]="#FF6666";
		} else {
			$tscolor[$listtable]="#66CCAA";
		}
	}
}


# main query
include("./includes/coalesced_query.php");

$result = mysql_query("$query") or die(mysql_error()); 
# echo "Sent query: '$query'.<br /><br />";
?>
<?php
echo "<div id=\"main\" style=\"float:none;width:90%;padding:20px;\"><table><tr>
<th class=\"head\" colspan=\"11\">Mediawiki statistics</th></tr><tr>
<th class=\"sub\">&#8470;</th>
<th class=\"sub\">project (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?sort=name_asc\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?sort=name_desc\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>
<th class=\"sub\">&#8470; of wikis (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?sort=numwikis_asc\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?sort=numwikis_desc\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>
<th class=\"sub\">good articles (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?sort=good_asc\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?sort=good_desc\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>
<th class=\"sub\">total pages (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?sort=total_asc\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?sort=total_desc\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>
<th class=\"sub\">edits (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?sort=edits_asc\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?sort=edits_desc\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>
<th class=\"sub\">images (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?sort=images_asc\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?sort=images_desc\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>
<th class=\"sub\">users (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?sort=users_asc\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?sort=users_desc\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>
<th class=\"sub\">admins (<a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?sort=admins_asc\"><b style=\"font-size: 120%;\">&uarr;</b></a><a style=\"text-decoration:none;\" href=\"".$_SERVER['PHP_SELF']."?sort=admins_desc\"><b style=\"font-size: 120%;\">&darr;</b></a>)</th>
<th class=\"sub\">stub ratio </th>
<th class=\"sub\" colspan=\"4\">formats </th>
<th class=\"sub\">last update</th></tr>";

$count=1;
$gtotal=0;
$ggood=0;
$gedits=0;
$gadmins=0;
$gusers=0;
$gimages=0;
$gwikis=0;

while($row = mysql_fetch_array( $result )) {

	$users=$row['gusers'];
	$gwikis=$gwikis+$row['numwikis'];
	$gtotal=$gtotal+$row['gtotal'];
	$ggood=$ggood+$row['ggood'];
	$gedits=$gedits+$row['gedits'];
	$gadmins=$gadmins+$row['gadmins'];
	$gusers=$gusers+$users;
	$gimages=$gimages+$row['gimages'];

	if ($row['gtotal']==0) {
		$stubratio=0;
	} else {
	$stubratio=$row['ggood']/$row['gtotal'];
	}

	$grandstubratio=0;
	$grandstubratio=$grandstubratio+$stubratio;
	$stubratio=round($stubratio, 4);
	$stubratio=number_format($stubratio, 4);
	$name=$row['name'];
	$project=$row['project'];

	# Check existence of format links and color green or red

	$file_formats = array ("html","wiki");

	foreach ($file_formats as &$file_format) {

		$filename=$name."_".$file_format.".php";

		if (file_exists($filename)) {
			$color[$file_format]="#66CCAA";
		} else {
			$color[$file_format]="#662266";
		}

	}

echo "<tr>
<td class=\"number\">$count</td>
<td style=\"background: ".$color['html'].";\" class=\"text\"><a href=\"display.php?t=".$project."\">$name</a></td>
<td class=\"text\">".$row['numwikis']."</td>
<td class=\"text\">".$row['ggood']."</td>
<td class=\"text\">".$row['gtotal']."</td>
<td class=\"text\">".$row['gedits']."</td>
<td class=\"text\">".$row['gimages']."</td>
<td class=\"text\">".$users."</td>
<td class=\"text\">".$row['gadmins']."</td>
<td class=\"text\">".$stubratio."</td>
<td class=\"formats\"><a href=\"api.php?action=dump&amp;table=$name&amp;format=csv\"> csv </a></td>
<td class=\"formats\"><a href=\"api.php?action=dump&amp;table=$name&amp;format=ssv\"> ssv </a></td>
<td class=\"formats\"><a href=\"api.php?action=dump&amp;table=$name&amp;format=xml\"> xml </a></td>
<td class=\"formats\" style=\"background: ".$color['wiki'].";\"><a href=\"display.php?t=".$project."&amp;o=wiki\"> mwiki </a></td>
<td class=\"timestamp\" style=\"background: ".$tscolor[$name].";\">".$timestamp[$name]."</td></tr>
";
}
# Wikimedias 

$query = <<<FNORD
(select good,total,edits,admins,users,images from wikipedias where prefix is not null)
 union all (select good,total,edits,admins,users,images from wikisources)
 union all (select good,total,edits,admins,users,images from wiktionaries)
 union all (select good,total,edits,admins,users,images from wikiquotes)
 union all (select good,total,edits,admins,users,images from wikibooks)
 union all (select good,total,edits,admins,users,images from wikinews)
 union all (select good,total,edits,admins,users,images from wmspecials)
 order by good;
FNORD;

$result = mysql_query("$query") or die(mysql_error());

$wm_wikis=0;
$wm_good=0;
$wm_total=0;
$wm_edits=0;
$wm_admins=0;
$wm_users=0;
$wm_images=0;

while($row = mysql_fetch_array( $result )) {
	$wm_wikis=$wm_wikis+1;
	$wm_good=$wm_good+$row['good'];
	$wm_total=$wm_total+$row['total'];
	$wm_edits=$wm_edits+$row['edits'];
	$wm_admins=$wm_admins+$row['admins'];
	$wm_users=$wm_users+$row['users'];
	$wm_images=$wm_images+$row['images'];
}

mysql_close();

$wm_ratio=$wm_good/$wm_total;
$wm_ratio=round($wm_ratio,4);
$wm_ratio=number_format($wm_ratio, 4);

$wm_wikis=number_format($wm_wikis, 0, ',', ' ');
$wm_good=number_format($wm_good, 0, ',', ' ');
$wm_total=number_format($wm_total, 0, ',', ' ');
$wm_edits=number_format($wm_edits, 0, ',', ' ');
$wm_admins=number_format($wm_admins, 0, ',', ' ');
$wm_users=number_format($wm_users, 0, ',', ' ');
$wm_images=number_format($wm_images, 0, ',', ' ');

$grandstubratio=$grandstubratio/$count;
$grandstubratio=round($grandstubratio, 4);
$grandstubratio=number_format($grandstubratio, 4);


$gwikis=number_format($gwikis, 0, ',', ' ');
$ggood=number_format($ggood, 0, ',', ' ');
$gtotal=number_format($gtotal, 0, ',', ' ');
$gedits=number_format($gedits, 0, ',', ' ');
$gadmins=number_format($gadmins, 0, ',', ' ');
$gusers=number_format($gusers, 0, ',', ' ');
$gimages=number_format($gimages, 0, ',', ' ');


# Check existence of format links and color green or red


$list_names = array ("largest","wikimedias");
$file_formats = array ("html","wiki");


foreach ($list_names as &$list_name) {

	foreach ($file_formats as &$file_format) {

		$filename=$list_name."_".$file_format.".php";
		# echo $filename."\n\n";

		if (file_exists($filename)) {
			$color[$file_format]="#66CCAA";
		} else {
			$color[$file_format]="#FF6600";
		}
	}
}


echo "</table></div><div id=\"grandtotals\" style=\"float:right;width:70%;padding:22px;\"><table><tr><th colspan=\"15\" class=\"grand\">grand totals</th></tr><tr><th></th><th class=\"grand\">wikis</th><th class=\"grand\">articles</th><th class=\"grand\">total</th><th class=\"grand\">edits</th><th class=\"grand\">admins</th><th class=\"grand\">users</th><th class=\"grand\">images</th><th class=\"grand\">stub ratio</th><th class=\"grand\" colspan=\"5\">formats</th></tr><tr><td style=\"background: ".$color['html'].";\" class=\"text\"><a href=\"wikimedias_html.php\">All wikimedia wikis</a></td><td class=\"grand\">$wm_wikis</td><td class=\"grand\"> $wm_good </td><td class=\"grand\"> $wm_total </td><td class=\"grand\"> $wm_edits </td><td class=\"grand\"> $wm_admins </td><td class=\"grand\"> $wm_users </td><td class=\"grand\"> $wm_images </td><td class=\"grand\"> $wm_ratio </td>
<td class=\"formats\"><a href=\"wikimedias_csv.php\"> csv </a></td>
<td class=\"formats\"><a href=\"wikimedias_ssv.php\"> ssv </a></td>
<td class=\"formats\"><a href=\"wikimedias_xml.php\"> xml </a></td>
<td class=\"formats\" style=\"background: ".$color['wiki'].";\"><a href=\"wikimedias_wiki.php\"> mwiki </a></td>
</tr><tr><td style=\"background: ".$color['html'].";\" class=\"text\"><a href=\"largest_html.php\">Largest wikis (all in one)</a></td><td class=\"grand\">$gwikis</td><td class=\"grand\"> $ggood </td><td class=\"grand\"> $gtotal </td><td class=\"grand\"> $gedits </td><td class=\"grand\"> $gadmins </td><td class=\"grand\"> $gusers </td><td class=\"grand\"> $gimages </td><td class=\"grand\"> $grandstubratio </td>
<td class=\"formats\"><a href=\"largest_csv.php\"> csv </a></td>
<td class=\"formats\"><a href=\"largest_ssv.php\"> ssv </a></td>
<td class=\"formats\"><a href=\"largest_xml.php\"> xml </a></td>
<td class=\"formats\" style=\"background: ".$color['wiki'].";\"><a href=\"largest_wiki.php\"> mwiki </a></td>
</tr></table></div>";


$name="coalesced";

echo <<<FORMATS
<ul><li>FIXME/WIP - This table ("coalesced") as: <a class="foot" href="${name}_csv.php">csv</a> - <a class="foot" href="${name}_ssv.php">ssv</a> - <a class="foot" href="${name}_xml.php">xml</a> - <a class="foot" href="${name}_wiki.php">mwiki</a></li>
<li><a href="./history/">Historic data can soon be found here</a></li>
</ul>
FORMATS;

echo <<<ALSOSEE
<hr />
<ul><li><a href="./rank.php">Get the rank of a project</a></li></ul>
ALSOSEE;

# Footer / W3C
echo <<<FOOTER
<p class="footer"> 
<a class="foot" href="http://validator.w3.org/check?uri=https://wikistats.wmflabs.org/index.php">
<img style="border:0;width:60px;" src="./images/valid-xhtml10-blue.png" alt="Valid XHTML 1.0 Strict" /></a>
FOOTER;

# CSS Validator
$selfurl=$_SERVER['HTTP_HOST'].$_SERVER['REQUEST_URI']; 
$selfurl=str_replace("&","&amp;",$selfurl);
echo <<<W3C
<a class="foot" href="http://jigsaw.w3.org/css-validator/validator?uri=http://${selfurl}">
<img style="border:0;width:60px;" src="./images/vcss-blue.png" alt="Valid CSS!" /></a>
<br />
W3C;

# Last Mod
echo "Last modified: " . date( "F d Y - H:i:s", getlastmod() );
echo "</p></body></html>";

?>
