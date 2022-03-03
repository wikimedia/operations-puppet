type Profile::Mediawiki_deployment = Struct[{
    'name'        => String,
    'canary'      => Optional[String],
    'mw_flavour'  => String,
    'web_flavour' => String,
    'debug'       => Boolean,
}]
