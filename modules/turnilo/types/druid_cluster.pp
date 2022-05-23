type Turnilo::Druid_cluster = Struct[{
    name                       => String,
    host                       => String,
    sourceListScan             => String,
    sourceListRefreshInterval  => Integer,
    sourceReintrospectInterval => Integer,
    type                       => Enum['druid'],
}]
