# SPDX-License-Identifier: Apache-2.0
# Tab completion for the pcc utility
# To install, copy or symlink this to $BASH_COMPLETION_USER_DIR/completions
#  (usually ~/.local/share/bash-completion/completions), without the .bash suffix.

_pcc() {
	local cur="${COMP_WORDS[COMP_CWORD]}"
	local prev="${COMP_WORDS[COMP_CWORD-1]}"
	COMPREPLY=()

	case "$prev" in
		--api-token)
			;;
		--username)
			;;
		-P|--puppet-version)
			mapfile -t COMPREPLY < <(compgen -W "7" -- "${cur}")
			;;
		--private-change)
			;;
		**)
			local options="--api-token --username -F --post-fail -C --post-crash -N --no-post-process -f --fail-fast -P --puppet-version --private-change"
			local i=$((subcmd_index + 1))

			local last_was_arg_with_param=0
			local had_patch_number=0

			while ((i<COMP_CWORD)); do
				if [[ "${COMP_WORDS[i]}" == "--api-token" ]]; then
					last_was_arg_with_param=1
					options="${options/--api-token/}"
				elif [[ "${COMP_WORDS[i]}" == "--username" ]]; then
					last_was_arg_with_param=1
					options="${options/--username/}"
				elif [[ "${COMP_WORDS[i]}" == "-F" || "${COMP_WORDS[i]}" == "--post-fail" ]]; then
					last_was_arg_with_param=0
					options="${options/-F/}"
					options="${options/--post-fail/}"
				elif [[ "${COMP_WORDS[i]}" == "-C" || "${COMP_WORDS[i]}" == "--post-crash" ]]; then
					last_was_arg_with_param=0
					options="${options/-C/}"
					options="${options/--post-crash/}"
				elif [[ "${COMP_WORDS[i]}" == "-N" || "${COMP_WORDS[i]}" == "--no-post-process" ]]; then
					last_was_arg_with_param=0
					options="${options/-N/}"
					options="${options/--no-post-process/}"
				elif [[ "${COMP_WORDS[i]}" == "-f" || "${COMP_WORDS[i]}" == "--fail-fast" ]]; then
					last_was_arg_with_param=0
					options="${options/-f/}"
					options="${options/--fail-fast/}"
				elif [[ "${COMP_WORDS[i]}" == "-P" || "${COMP_WORDS[i]}" == "--puppet-version" ]]; then
					last_was_arg_with_param=1
					options="${options/-P/}"
					options="${options/--puppet-version/}"
				elif [[ "${COMP_WORDS[i]}" == "--private-change" ]]; then
					last_was_arg_with_param=1
					options="${options/--private-change/}"
				elif [[ "$last_was_arg_with_param" == "0" ]]; then
					had_patch_number=1
				fi

				((++i))
			done

			if [[ $cur == -* ]]; then
				mapfile -t COMPREPLY < <(compgen -W "${options}" -- "${cur}")
			elif [[ "$had_patch_number" == "1" ]]; then
				_comp_compgen_known_hosts -- "$cur"
			fi
			;;
	esac
}

complete -F _pcc pcc
