type Puppetmaster::R10k::Source = Struct[{
    remote                 => String,
    basedir                => Stdlib::Unixpath,
    prefix                 => Optional[Variant[Boolean, String]],
    strip_component        => Optional[String],
    ignore_branch_prefixes => Optional[Array[String]],
}]
