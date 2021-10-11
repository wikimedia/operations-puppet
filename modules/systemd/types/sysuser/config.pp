type Systemd::Sysuser::Config = Struct[{
    usertype => Enum['u', 'g', 'm', 'r'],  # 'type' may be reserved
    id => Variant[Integer[0], Enum['-'], Stdlib::Unixpath, Pattern[/\d+\-\d+/]],
    gecos => Optional[String[1]],
    home_dir => Optional[Stdlib::Unixpath],
    shell => Optional[Stdlib::Unixpath],
    ensure => Optional[Wmflib::Ensure],
}]
