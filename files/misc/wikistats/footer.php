<?php
#$wikioutput=$listtable."_wiki.php";
$wikioutput="";
$selfurl=$_SERVER['HTTP_HOST'].$_SERVER['REQUEST_URI']; $selfurl=str_replace("&","&amp;",$selfurl); 
?>
<ul><li><a class="foot" href="<?php echo "$wikioutput"; ?>">Table in Mediawiki Syntax</a></li>
<li>In use on: <a class="foot" href="<?php echo "$wikipage"; ?>"><?php echo "$wikipage"; ?></a></li>
<li><a class="foot" href="index.php">Back to Index</a></li></ul>
<a class="foot" href="http://validator.w3.org/check?uri=<?php echo "http://".$selfurl; ?>">
<img style="border:0;width:60px;" src="./images/valid-xhtml10-blue.png" alt="Valid XHTML 1.0 Strict" /></a>
<a class="foot" href="http://jigsaw.w3.org/css-validator/validator?uri=<?php echo "http://".$selfurl; ?>">
<img style="border:0;width:60px;" src="./images/vcss-blue.png" alt="Valid CSS!" /></a>
<br />
<?php echo "Last modified: " . date( "F d Y - H:i:s", getlastmod() ); ?>
