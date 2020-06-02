type Systemd::Sysuser::Config = Struct[{
    usertype => Enum['u', 'g', 'm', 'r'],  # 'type' may be reserved
    name => String,
    id => Variant[Integer[0], Enum['-'], Stdlib::Unixpath, Pattern[/\d+\-\d+/]],
    gecos => Optional[String[1]],
    home_dir => Optional[Stdlib::Unixpath],
    shell => Optional[Stdlib::Unixpath],
}]
