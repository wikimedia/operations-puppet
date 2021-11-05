type Bird::Anycasthc_logging = Struct[{
    level       => Enum['debug', 'info', 'warning', 'error', 'critical'],
    num_backups => Integer[1],
}]
