<?php
# wikistats - statistics about mediawikis
header('Last-Modified: '.getlastmod());
header('Content-type: text/html; charset=utf-8');
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
<title>wikistats - Mediawiki statistics</title>
<meta name="author" content="dzahn@wikimedia.org" />
<meta name="description" content="various Mediawiki statistics tables" />
<meta name="keywords" content"=wiki,statistics,mediawiki,wikimedia,wikipedia,tables,growth,wikiquotes,wiktionaries,wiktionary,wikibooks,wikisource,wikicities,editthis,wiki-site,gratiswiki,opensuse,anarchopedia,uncyclomedia,uncyclopedia,wikitravel,wikia,wikicities,wikifur,neoseeker,shoutwiki" />
</head>
<body>
<h4>Wikistats</h4>
<?php
echo "Last modified: " . date( "F d Y - H:i:s", getlastmod() ) . "</body></html>";
?>
