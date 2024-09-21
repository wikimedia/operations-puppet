type Profile::Mediawiki_deployment = Struct[{
    'namespace'   => String,
    'releases'    => Hash[String, Struct[{
        'mw_flavour'  => Optional[String],
        'web_flavour' => Optional[String],
        'stage'       => Optional[Enum['canaries']],
    }]],
    'mw_flavour'  => String,
    'web_flavour' => String,
    'debug'       => Boolean,
}]
