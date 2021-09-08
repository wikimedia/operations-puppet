# == Type: Profile::Durum::Common
#
# Common configurations used by durum.
#
#  [*durum_path*]
#    [directory path] install path for durum web application scripts.

type Profile::Durum::Common = Struct[{
    durum_path    => Stdlib::Unixpath,
}]
