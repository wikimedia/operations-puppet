type Turnilo::Druid_cluster = Struct[{
    name                       => String,
    host                       => String,
    sourceListRefreshInterval  => Integer,
    sourceReintrospectInterval => Integer,
    type                       => Enum['druid'],
}]
