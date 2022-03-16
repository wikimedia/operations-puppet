# @summery add a set of environment variables for use by systemd user services.
#   WMF specific: if profile::environment::export_systemd_env: true theses variables will also
#   get injected into user shells.
# @param ensure ensureable
# @param priority the priority to install the files
# @param variables A hash of environment variables
define  systemd::environment (
    Hash[Pattern[/\A\w+\z/], String[1], 1] $variables,
    Wmflib::Ensure                         $ensure   = 'present',
    Integer[0,99]                          $priority = 50,
) {
    $base_dir = '/etc/environment.d'
    $safe_title = $title.regsubst('[^\w\-]', '_', 'G')
    ensure_resource('file', $base_dir, {'ensure' => 'directory'})
    $file_path = sprintf('%s/%02d-%s.conf', $base_dir, $priority, $safe_title)
    $content = $variables.reduce('') |$memo, $value| {
        "${memo}${value[0]}=\"${value[1]}\"\n"
    }
    file { $file_path:
        ensure  => stdlib::ensure($ensure, 'file'),
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => $content,
    }
}
