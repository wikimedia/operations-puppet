# == git::config
#
# Set a particular configuration value for a particular git repository
#
# Parameters:
#  [*git_config_file*] - Git directory we're calling `git config` on
#  [*name*] - Name of the gitconfig setting
#  [*value*] - Value to set. Passing undef will cause it to be removed
#  [*user*] - What user to execute git config as
#
define git::config($git_config_file, $name, $value, $user = 'root') {
    if $value == undef {
        exec{ "${git_config_file}_${name}":
            command => "git config -f ${git_config_file} --unset \"${name}\"",
            unless  => "test \"$(git config -f ${git_config_file} \"${name}\")",
            user    => $user,
        }
    } else {
        exec{ "${git_config_file}_${name}":
            command => "git config -f ${git_config_file} \"${name}\" \'${value}\'",
            unless  => "test \"$(git config -f ${git_config_file} \"${name}\")\" = \'${value}\'",
            user    => $user,
        }
    }
}
