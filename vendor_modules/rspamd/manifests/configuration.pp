# @api private
# This class handles configuration. Avoid modifying private classes.
class rspamd::configuration {
  assert_private()
  include rspamd
  if ($rspamd::purge_unmanaged) {
    file { 'purge unmanaged rspamd local.d files':
      ensure  => 'directory',
      path    => "${rspamd::config_path}/local.d",
      recurse => true,
      purge   => true,
    }
    file { 'purge unmanaged rspamd override.d files':
      ensure  => 'directory',
      path    => "${rspamd::config_path}/override.d",
      recurse => true,
      purge   => true,
    }
  }

  rspamd::create_config_file_resources($rspamd::config)
}
