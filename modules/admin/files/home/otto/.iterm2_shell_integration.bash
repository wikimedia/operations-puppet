#!/bin/bash
# This is based on "preexec.bash" but is customized for iTerm2.

# Note: this module requires 2 bash features which you must not otherwise be
# using: the "DEBUG" trap, and the "PROMPT_COMMAND" variable.  iterm2_preexec_install
# will override these and if you override one or the other this _will_ break.

# This is known to support bash3, as well as *mostly* support bash2.05b.  It
# has been tested with the default shells on MacOS X 10.4 "Tiger", Ubuntu 5.10
# "Breezy Badger", Ubuntu 6.06 "Dapper Drake", and Ubuntu 6.10 "Edgy Eft".

# tmux and screen are not supported; even using the tmux hack to get escape
# codes passed through, ncurses interferes and the cursor isn't in the right
# place at the time it's passed through.
if [[ "$TERM" != screen && "$ITERM_SHELL_INTEGRATION_INSTALLED" = "" && "$-" == *i* ]]; then
  ITERM_SHELL_INTEGRATION_INSTALLED=Yes
  # Saved copy of your PS1. This is used to detect if the user changes PS1
  # directly. ITERM_PREV_PS1 will hold the last value that this script set PS1 to
  # (including various custom escape sequences).
  ITERM_PREV_PS1="$PS1"

  # This variable describes whether we are currently in "interactive mode";
  # i.e. whether this shell has just executed a prompt and is waiting for user
  # input.  It documents whether the current command invoked by the trace hook is
  # run interactively by the user; it's set immediately after the prompt hook,
  # and unset as soon as the trace hook is run.
  ITERM_PREEXEC_INTERACTIVE_MODE=""

  # Default do-nothing implementation of preexec.
  function preexec () {
      true
  }

  # Default do-nothing implementation of precmd.
  function precmd () {
      true
  }

  # This function is installed as the PROMPT_COMMAND; it is invoked before each
  # interactive prompt display.  It sets a variable to indicate that the prompt
  # was just displayed, to allow the DEBUG trap, below, to know that the next
  # command is likely interactive.
  function iterm2_preexec_invoke_cmd () {
      # Ideally we could do this in iterm2_preexec_install but CentOS 7.2 and
      # RHEL 7.2 complain about bashdb-main.inc not existing if you do that
      # (issue 4160).
      # *BOTH* of these options need to be set for the DEBUG trap to be invoked
      # in ( ) subshells.  This smells like a bug in bash to me.  The null stackederr
      # redirections are to quiet errors on bash2.05 (i.e. OSX's default shell)
      # where the options can't be set, and it's impossible to inherit the trap
      # into subshells.
      set -o functrace > /dev/null 2>&1
      shopt -s extdebug > /dev/null 2>&1

      \local s=$?
      last_hist_ent="$(HISTTIMEFORMAT= builtin history 1)";
      precmd;
      # This is an iTerm2 addition to try to work around a problem in the
      # original preexec.bash.
      # When the PS1 has command substitutions, this gets invoked for each
      # substitution and each command that's run within the substitution, which
      # really adds up. It would be great if we could do something like this at
      # the end of this script:
      #   PS1="$(iterm2_prompt_prefix)$PS1($iterm2_prompt_suffix)"
      # and have iterm2_prompt_prefix set a global variable that tells precmd not to
      # output anything and have iterm2_prompt_suffix reset that variable.
      # Unfortunately, command substitutions run in subshells and can't
      # communicate to the outside world.
      # Instead, we have this workaround. We save the original value of PS1 in
      # $ITERM_ORIG_PS1. Then each time this function is run (it's called from
      # PROMPT_COMMAND just before the prompt is shown) it will change PS1 to a
      # string without any command substitutions by doing eval on ITERM_ORIG_PS1. At
      # this point ITERM_PREEXEC_INTERACTIVE_MODE is still the empty string, so preexec
      # won't produce output for command substitutions.

      # The first time this is called ITERM_ORIG_PS1 is unset. This tests if the variable
      # is undefined (not just empty) and initializes it. We can't initialize this at the
      # top of the script because it breaks with liquidprompt. liquidprompt wants to
      # set PS1 from a PROMPT_COMMAND that runs just before us. Setting ITERM_ORIG_PS1
      # at the top of the script will overwrite liquidprompt's PS1, whose value would
      # never make it into ITERM_ORIG_PS1. Issue 4532. It's important to check
      # if it's undefined before checking if it's empty because some users have
      # bash set to error out on referencing an undefined variable.
      if [ -z "${ITERM_ORIG_PS1+xxx}" ]
      then
        # ITERM_ORIG_PS1 always holds the last user-set value of PS1.
        # You only get here on the first time iterm2_preexec_invoke_cmd is called.
        export ITERM_ORIG_PS1="$PS1"
      fi

      if [[ "$PS1" != "$ITERM_PREV_PS1" ]]
      then
        export ITERM_ORIG_PS1="$PS1"
      fi

      # Get the value of the prompt prefix, which will change $?
      \local iterm2_prompt_prefix_value="$(iterm2_prompt_prefix)"

      # Reset $? to its saved value, which might be used in $ITERM_ORIG_PS1.
      sh -c "exit $s"

      # Set PS1 to various escape sequences, the user's preferred prompt, and more escape sequences.
      export PS1="\[$iterm2_prompt_prefix_value\]$ITERM_ORIG_PS1\[$(iterm2_prompt_suffix)\]"

      # Save the value we just set PS1 to so if the user changes PS1 we'll know and we can update ITERM_ORIG_PS1.
      export ITERM_PREV_PS1="$PS1"
      sh -c "exit $s"

      # This must be the last line in this function, or else
      # iterm2_preexec_invoke_exec will do its thing at the wrong time.
      ITERM_PREEXEC_INTERACTIVE_MODE="yes";
  }

  # This function is installed as the DEBUG trap.  It is invoked before each
  # interactive prompt display.  Its purpose is to inspect the current
  # environment to attempt to detect if the current command is being invoked
  # interactively, and invoke 'preexec' if so.
  function iterm2_preexec_invoke_exec () {
      if [ ! -t 1 ]
      then
          # We're in a piped subshell (STDOUT is not a TTY) like
          #   (echo -n A; sleep 1; echo -n B) | wc -c
          # ...which should return "2".
          return
      fi
      if [[ -n "${COMP_LINE:-}" ]]
      then
          # We're in the middle of a completer.  This obviously can't be
          # an interactively issued command.
          return
      fi
      if [[ -z "$ITERM_PREEXEC_INTERACTIVE_MODE" ]]
      then
          # We're doing something related to displaying the prompt.  Let the
          # prompt set the title instead of me.
          return
      else
          # If we're in a subshell, then the prompt won't be re-displayed to put
          # us back into interactive mode, so let's not set the variable back.
          # In other words, if you have a subshell like
          #   (sleep 1; sleep 2)
          # You want to see the 'sleep 2' as a set_command_title as well.
          if [[ 0 -eq "$BASH_SUBSHELL" ]]
          then
              ITERM_PREEXEC_INTERACTIVE_MODE=""
          fi
      fi
      if [[ "iterm2_preexec_invoke_cmd" == "$BASH_COMMAND" ]]
      then
          # Sadly, there's no cleaner way to detect two prompts being displayed
          # one after another.  This makes it important that PROMPT_COMMAND
          # remain set _exactly_ as below in iterm2_preexec_install.  Let's switch back
          # out of interactive mode and not trace any of the commands run in
          # precmd.

          # Given their buggy interaction between BASH_COMMAND and debug traps,
          # versions of bash prior to 3.1 can't detect this at all.
          ITERM_PREEXEC_INTERACTIVE_MODE=""
          return
      fi

      # In more recent versions of bash, this could be set via the "BASH_COMMAND"
      # variable, but using history here is better in some ways: for example, "ps
      # auxf | less" will show up with both sides of the pipe if we use history,
      # but only as "ps auxf" if not.
      hist_ent="$(HISTTIMEFORMAT= builtin history 1)";
      \local prev_hist_ent="${last_hist_ent}";
      last_hist_ent="${hist_ent}";
      if [[ "${prev_hist_ent}" != "${hist_ent}" ]]; then
          \local this_command="$(echo "${hist_ent}" | sed -e "s/^[ ]*[0-9]*[ ]*//g")";
      else
          \local this_command="";
      fi;

      # If none of the previous checks have earlied out of this function, then
      # the command is in fact interactive and we should invoke the user's
      # preexec hook with the running command as an argument.
      preexec "$this_command";
  }

  # Execute this to set up preexec and precmd execution.
  function iterm2_preexec_install () {
      # Finally, install the actual traps.
      if ( [ x"${PROMPT_COMMAND:-}" = x ]); then
        PROMPT_COMMAND="iterm2_preexec_invoke_cmd";
      else
        # If there's a trailing semicolon folowed by spaces, remove it (issue 3358).
        PROMPT_COMMAND="$(echo -n $PROMPT_COMMAND | sed -e 's/; *$//'); iterm2_preexec_invoke_cmd";
      fi
      # The $_ is ignored, but prevents it from changing (issue 3932).
      trap 'iterm2_preexec_invoke_exec "$_"' DEBUG;
  }

  # -- begin iTerm2 customization

  function iterm2_begin_osc {
    printf "\033]"
  }

  function iterm2_end_osc {
    printf "\007"
  }

  # Runs after interactively edited command but before execution
  function preexec() {
    iterm2_begin_osc
    printf "133;C;"
    iterm2_end_osc
    # If PS1 still has the value we set it to in iterm2_preexec_invoke_cmd then
    # restore it to its original value. It might have changed if you have
    # another PROMPT_COMMAND (like liquidprompt) that modifies PS1.
    if [ -n "${ITERM_ORIG_PS1+xxx}" -a "$PS1" = "$ITERM_PREV_PS1" ]
    then
      export PS1="$ITERM_ORIG_PS1"
    fi
    iterm2_ran_preexec="yes"
  }

  function precmd () {
      # Work around a bug in CentOS 7.2 where preexec doesn't run if you press
      # ^C while entering a command.
      if [[ -z "${iterm2_ran_preexec:-}" ]]
      then
          preexec ""
      fi
      iterm2_ran_preexec=""
  }

  function iterm2_print_state_data() {
    iterm2_begin_osc
    printf "1337;RemoteHost=%s@%s" "$USER" "$iterm2_hostname"
    iterm2_end_osc

    iterm2_begin_osc
    printf "1337;CurrentDir=%s" "$PWD"
    iterm2_end_osc

    iterm2_print_user_vars
  }

  # Usage: iterm2_set_user_var key value
  function iterm2_set_user_var() {
    iterm2_begin_osc
    printf "1337;SetUserVar=%s=%s" "$1" $(printf "%s" "$2" | base64)
    iterm2_end_osc
  }

  if [ -z "$(type -t iterm2_print_user_vars)" ] || [ "$(type -t iterm2_print_user_vars)" != function ]; then
    # iterm2_print_user_vars is not already defined. Provide a no-op default version.
    #
    # Users can write their own version of this function. It should call
    # iterm2_set_user_var but not produce any other output.
    function iterm2_print_user_vars() {
      true
    }
  fi

  function iterm2_prompt_prefix() {
    iterm2_begin_osc
    printf "133;D;\$?"
    iterm2_end_osc

    iterm2_print_state_data

    iterm2_begin_osc
    printf "133;A"
    iterm2_end_osc
  }

  function iterm2_prompt_suffix() {
    iterm2_begin_osc
    printf "133;B"
    iterm2_end_osc
  }

  function iterm2_print_version_number() {
    iterm2_begin_osc
    printf "1337;ShellIntegrationVersion=2;shell=bash"
    iterm2_end_osc
  }


  # If hostname -f is slow on your system, set iterm2_hostname before sourcing this script.
  if [ -z "${iterm2_hostname:-}" ]; then
    iterm2_hostname=$(hostname -f)
  fi
  iterm2_preexec_install

  # This is necessary so the first command line will have a hostname and current directory.
  iterm2_print_state_data
  iterm2_print_version_number
fi
