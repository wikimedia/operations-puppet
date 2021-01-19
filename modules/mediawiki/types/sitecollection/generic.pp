type Mediawiki::SiteCollection::Generic = Struct[{
    'name' => String,
    'priority' => Integer[0,99],
    'template'  => Optional[String],
    'source'   => Optional[String]
}]
