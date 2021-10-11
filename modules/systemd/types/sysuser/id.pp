type Systemd::Sysuser::Id = Variant[
    Integer[0],                # uid: valid gor group and user
    Enum['-'],                 # automatic: valid for user and group
    Stdlib::Unixpath,          # pathname: valid for user and group
    Pattern[/\A\d+:\d+\z/],    # uid:gid: valid for users
    Pattern[/\A\d+:[\w-]+\z/], # uid:groupname valid for users
    Pattern[/\A[\w-]+\z/],      # groupname: valid for modify
    Pattern[/\A\d+\-\d+\z/]    # $lowuid-$highuid: valid for range
]
