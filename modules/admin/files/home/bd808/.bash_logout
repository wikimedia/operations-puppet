# cleanup any dbus session that we made
[[ -n $DBUS_SESSION_BUS_PID ]] &&
  kill $DBUS_SESSION_BUS_PID > /dev/null 2>&1
