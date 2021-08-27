# == Type: Profile::Durum::Common
#
# Common configurations used by durum.
#
#  [*durum_path*]
#    [directory path] install path for durum web application scripts.
#
#  [*sock_file*]
#    [file path] socket path for uWSGI.
#
#  [*app_file*]
#    [string] path of the durum script called by uWSGI.
#
#  [*template_file*]
#    [string] path of the Flask template file.

type Profile::Durum::Common = Struct[{
    durum_path    => Stdlib::Unixpath,
    sock_file     => Stdlib::Unixpath,
    app_file      => String,
    template_file => String,
}]
