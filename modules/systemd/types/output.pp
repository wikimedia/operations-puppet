type Systemd::Output = Variant[
  Enum['inherit', 'null', 'tty', 'journal', 'kmsg', 'journal+console', 'kmsg+console', 'socket'],
  # Fairly loose match
  Pattern[/(file|append|truncate|fd)(:[^\W]+)?/],
]
