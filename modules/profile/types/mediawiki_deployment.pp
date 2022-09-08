type Profile::Mediawiki_deployment = Struct[{
    'namespace'   => String,
    'release'     => String,
    'canary'      => Optional[String],
    'mw_flavour'  => String,
    'web_flavour' => String,
    'debug'       => Boolean,
}]
