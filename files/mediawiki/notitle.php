<?php
#####################################################################
### THIS FILE IS MANAGED BY PUPPET
### puppet:///files/mediawiki/notitle.php
###
###  Changes to this file will be clobbered by Puppet.
###  If you need to hand-edit local settings, modify
###  the included orig/LocalSettings.php.
###
#####################################################################
$wgExtensionCredits['parserhook'][] = array(
    'name' => 'No title',
    'author' => '[http://www.mediawiki.org/wiki/User:Nx Nx]',
    'description' => 'Adds a magic word to hide the title heading.'
    );

$wgHooks['LanguageGetMagic'][] = 'NoTitle::addMagicWordLanguage';
$wgHooks['ParserBeforeTidy'][] = 'NoTitle::checkForMagicWord';


class NoTitle
{
	static function addMagicWordLanguage(&$magicWords, $langCode) {
		switch($langCode) {
		default:
			$magicWords['notitle'] = array(0, '__NOTITLE__');
		}
		MagicWord::$mDoubleUnderscoreIDs[] = 'notitle';
        return true;
	}

        static function checkForMagicWord(&$parser, &$text) {
			if ( isset( $parser->mDoubleUnderscores['notitle'] ) ) {
				$parser->mOutput->addHeadItem('<style type="text/css">/*<![CDATA[*/ .firstHeading, .subtitle, #siteSub, #contentSub, .pagetitle { display:none; } /*]]>*/</style>');
			}
			return true;
		}

}

