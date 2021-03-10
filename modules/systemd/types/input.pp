type Systemd::Input = Variant[
  Enum['null', 'tty', 'tty-force', 'tty-fail', 'data', 'socket'],
  # Fairly loose match
  Pattern[/(file|fd)(:[^\W]+)?/],
]
