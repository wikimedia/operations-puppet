# == Type: Profile::Durum::Messages
#
# Message strings that are consumed by the durum web application and shown as
# output on the results page.
#
#  [*check_success*]
#    [string] message printed when user is using Wikidough.
#
#  [*check_failure*]
#    [string] message printed when user is not using Wikidough.
#
#  [*check_error*]
#    [string] message printed when an unknown error occurred.

type Profile::Durum::Messages = Struct[{
    check_success => String,
    check_failure => String,
    check_error   => String,
}]
