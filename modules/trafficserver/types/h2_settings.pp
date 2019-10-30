# Trafficserver::H2_settings wraps HTTP/2 settings defined on
# https://docs.trafficserver.apache.org/en/latest/admin-guide/files/records.config.en.html#http-2-configuration
#
# [*stream_priority_enabled*]
#   Enable the experimental HTTP/2 Stream Priority feature.
#
# [*max_settings_per_frame*]
#   Specifies how many settings in an HTTP/2 SETTINGS frame Traffic Server accepts.
#
# [*max_settings_per_minute*]
#   Specifies how many settings in HTTP/2 SETTINGS frames Traffic Server accept for a minute.
#
# [*max_settings_frames_per_minute*]
#   Specifies how many SETTINGS frames Traffic Server receives for a minute at maximum.
#
# [*max_ping_frames_per_minute*]
#   Specifies how many number of PING frames Traffic Server receives for a minute at maximum.
#
# [*max_priority_frames_per_minute*]
#   Specifies how many number of PRIORITY frames Traffic Server receives for a minute at maximum.
#   Setting this value to 0 disables the limit.
#
# [*min_avg_window_update*]
#   Specifies the minimum average window increment Traffic Server allows.
#   The average will be calculated based on the last 5 WINDOW_UPDATE frames
#
# [*accept_no_activity_timeout*]
#   The timeout interval in seconds before Traffic Server closes a connection that has no activity.
#
# [*no_activity_timeout_in*]
#   Specifies how long Traffic Server keeps connections to clients open if a transaction stalls.
#
# [*stream_error_rate_threshold*]
#   This is the maximum stream error rate Traffic Server allows on an HTTP/2 connection.
#
type Trafficserver::H2_settings = Struct[{
    'stream_priority_enabled'        => Integer[0, 1],
    'max_settings_per_frame'         => Integer[0],
    'max_settings_per_minute'        => Integer[0],
    'max_settings_frames_per_minute' => Integer[0],
    'max_ping_frames_per_minute'     => Integer[0],
    'max_priority_frames_per_minute' => Integer[0],
    'min_avg_window_update'          => Float[0.0],
    'accept_no_activity_timeout'     => Integer[0],
    'no_activity_timeout_in'         => Integer[0],
    'stream_error_rate_threshold'    => Float[0.0],
}]
