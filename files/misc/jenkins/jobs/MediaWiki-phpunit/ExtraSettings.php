<?php
# This file will be included by LocalSettings.php

$ext = dirname( __FILE__ ) . '/workspace/mw-extensions';
require_once( "$ext/Cite/Cite.php" );
require_once( "$ext/CodeReview/CodeReview.php" );
require_once( "$ext/Gadgets/Gadgets.php" );
#require_once( "$ext/FlaggedRevs/FlaggedRevs.php" );
require_once( "$ext/LabeledSectionTransclusion/lst.php" );
require_once( "$ext/ParserFunctions/ParserFunctions.php" );
require_once( "$ext/Poem/Poem.php" );

$wgPFEnableStringFunctions = true; # fully test ParserFunctions

$wgShowExceptionDetails = true;
$wgShowSQLErrors = true;
#$wgDebugLogFile = dirname( __FILE__ ) . '/build/debug.log';
$wgDebugDumpSql = true;

