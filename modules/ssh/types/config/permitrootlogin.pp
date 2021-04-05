type Ssh::Config::PermitRootLogin = Variant[
  Boolean,
  Enum['prohibit-password', 'forced-commands-only', 'yes', 'no']
]
