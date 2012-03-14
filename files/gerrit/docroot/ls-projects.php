# Potentially list all gerrit projects under 'mediawiki/extensions'
#
# The script generating this output, is available in operations/puppet
# file:///puppet/files/gerrit/docroot/ls-projects.php
#
<?php
$out = shell_exec( "/bin/ls -1 /var/lib/gerrit2/review_site/git/mediawiki/extensions/*.git" );
if( $out == NULL ) {
	echo "# ERROR listing content of gerrit directories :-(\n";
}
?>
# End of script
