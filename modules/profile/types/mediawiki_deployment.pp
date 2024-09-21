# TODO: T370934 - Remove the older format and surrounding Variant once all
# deployments are migrated.
type Profile::Mediawiki_deployment = Variant[Struct[{
        'namespace'   => String,
        'release'     => String,
        'canary'      => Optional[String],
        'mw_flavour'  => String,
        'web_flavour' => String,
        'debug'       => Boolean,
    }],
    Struct[{
        'namespace'   => String,
        'releases'    => Hash[String, Struct[{
            'mw_flavour'  => Optional[String],
            'web_flavour' => Optional[String],
            'stage'       => Optional[Enum['canaries']],
        }]],
        'mw_flavour'  => String,
        'web_flavour' => String,
        'debug'       => Boolean,
}]]
