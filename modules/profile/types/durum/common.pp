# == Type: Profile::Durum::Common
#
# Common configurations used by durum.
#
#  [*durum_path*]
#    [path] install path for durum web application scripts.
#
#  [*app_path*]
#    [path] path of the durum script called by uWSGI.
#
#  [*sock_path*]
#    [path] socket path for uWSGI.

type Profile::Durum::Common = Struct[{
    durum_path => Stdlib::Unixpath,
    app_path  => Stdlib::Unixpath,
    sock_path => Stdlib::Unixpath,
}]
