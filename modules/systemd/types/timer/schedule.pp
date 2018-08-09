type Systemd::Timer::Schedule = Struct[
    {
    'start'    => Systemd::Timer::Start,
    'interval' => Variant[
        Systemd::Timer::Interval,
        Systemd::Timer::Datetime,
    ]
    }
]
