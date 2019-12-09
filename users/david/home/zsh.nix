{ config, pkgs, lib, ... }:

# This file contains the configuration for zsh.

let
  plugins = pkgs.callPackage ./plugins.nix {};
in
{
  programs.zsh = {
    defaultKeymap = "viins";
    enable = true;
    history = {
      extended = true;
      ignoreDups = true;
      save = 99999999;
      share = false;
    };
    # On non-NixOS systems, need to manually source `nix.sh`.
    #
    # When the non-NixOS system is a WSL system, this goes through `.profile` because we can't
    # change shell with `chsh`. When it is not a WSL system, we go directly to `.zprofile`. So that
    # we don't duplicate this sourcing of `nix.sh`, we only set it in `.zprofile` and then pull it
    # in using the `config.programs.zsh` variable in the `.profile` definition (appending the shell
    # exec if WSL).
    profileExtra = lib.mkIf (config.veritas.david.dotfiles.isNonNixOS) (
      ''
        if [ -f ${config.home.profileDirectory}/etc/profile.d/nix.sh ]; then
          . "${config.home.profileDirectory}/etc/profile.d/nix.sh"
        elif [ -f /etc/profile.d/nix.sh ]; then
          . "/etc/profile.d/nix.sh"
        fi
      ''
    );
    initExtra = ''
      if [ -t 1 ]; then
        BLACK="$(tput setaf 0)"
        RED="$(tput setaf 1)"
        GREEN="$(tput setaf 2)"
        YELLOW="$(tput setaf 3)"
        BLUE="$(tput setaf 4)"
        MAGENTA="$(tput setaf 5)"
        CYAN="$(tput setaf 6)"
        WHITE="$(tput setaf 7)"
        BRIGHT_BLACK="$(tput setaf 8)"
        BRIGHT_RED="$(tput setaf 9)"
        BRIGHT_GREEN="$(tput setaf 10)"
        BRIGHT_YELLOW="$(tput setaf 11)"
        BRIGHT_BLUE="$(tput setaf 12)"
        BRIGHT_MAGENTA="$(tput setaf 13)"
        BRIGHT_CYAN="$(tput setaf 14)"
        BRIGHT_WHITE="$(tput setaf 15)"
        BOLD="$(tput bold)"
        UNDERLINE="$(tput sgr 0 1)"
        INVERT="$(tput sgr 1 0)"
        RESET="$(tput sgr0)"
      else
        BLACK=""
        RED=""
        GREEN=""
        YELLOW=""
        BLUE=""
        MAGENTA=""
        CYAN=""
        WHITE=""
        BRIGHT_BLACK=""
        BRIGHT_RED=""
        BRIGHT_GREEN=""
        BRIGHT_YELLOW=""
        BRIGHT_BLUE=""
        BRIGHT_MAGENTA=""
        BRIGHT_CYAN=""
        BRIGHT_WHITE=""
        BOLD=""
        UNDERLINE=""
        INVERT=""
        RESET=""
      fi

      # Use modern completion system.
      autoload -Uz +X compinit && compinit

      # Execute code in the background to not affect the current session.
      {
          # Compile zcompdump, if modified, to increase startup speed.
          zcompdump="''${ZDOTDIR:-$HOME}/.zcompdump"
          if [[ -s "$zcompdump" ]] && \
             [[ (! -s "''${zcompdump}.zwc" || "$zcompdump" -nt "''${zcompdump}.zwc") ]]; then
            zcompile -U "$zcompdump"
          fi
      } &!

      # Load colour variables.
      eval "$(dircolors -b)"

      # Description for options that are not described by completion functions.
      zstyle ':completion:*' auto-description "''${BRIGHT_BLACK}Specify %d''${RESET}"
      # Enable corrections, expansions, completions and approximate completers.
      zstyle ':completion:*' completer _expand _complete _correct _approximate
      # Display 'Completing $section' between types of matches, ie. 'Completing external command'
      zstyle ':completion:*' format "''${BRIGHT_BLACK}Completing %d''${RESET}"
      # Display all types of matches separately (same types as above).
      zstyle ':completion:*' group-name ''\'''\'
      # Use menu selection if there are more than two matches (or when not on screen).
      zstyle ':completion:*' menu select=2
      zstyle ':completion:*' menu select=long
      # Set colour specifications.
      zstyle ':completion:*:default' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*' list-colors ''\'''\'
      # Prompt to show when completions don't fit on screen.
      zstyle ': completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
      zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
      # Define matcher specifications.
      zstyle ':completion:*' matcher-list ''\'''\' 'm: { a-z }={A-Z}' 'm: { a-zA-Z }={A-Za-z}' \
        'r: |[ ._- ]=* r:|=* l:|=*'
      # Don't use legacy `compctl`.
      zstyle ':completion:*' use-compctl false
      # Show command descriptions.
      zstyle ':completion:*' verbose true
      # Extra patterns to accept.
      zstyle ':completion:*' accept-exact '*(N)'
      # Enable caching.
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path $ZSH_CACHE_DIR

      # Extra settings for processes.
      zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
      zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

      # Modify git completion for only local files and branches - much faster!
      __git_files () { _wanted files expl 'local files' _files  }

      # Configure message format for you-should-use.
      export YSU_MESSAGE_FORMAT="''${BRIGHT_BLACK}Consider using the %alias_type\
        \"''${WHITE}%alias''${BRIGHT_BLACK}\"''${RESET}"
    '' + (
      if config.veritas.david.dotfiles.isWsl then ''
        _run_npiperelay() {
          # This function will forward a named pipe from Windows to a socket in WSL. It expects
          # `npiperelay.exe` (from https://github.com/NZSmartie/npiperelay/releases) to exist at
          # `C:\npiperelay.exe`.
          SOCAT_PID_FILE="$1"
          SOCKET_PATH="$2"
          WINDOWS_PATH="$3"

          if [[ -f $SOCAT_PID_FILE ]] && kill -0 $(${pkgs.coreutils}/bin/cat $SOCAT_PID_FILE); then
            : # Already running.
          else
            rm -f "$SOCKET_PATH"
            EXEC="/mnt/c/npiperelay.exe -ei -ep -s -a '$WINDOWS_PATH'"
            (trap "rm $SOCAT_PID_FILE" EXIT; \
              ${pkgs.socat}/bin/socat UNIX-LISTEN:$SOCKET_PATH,fork EXEC:$EXEC,nofork \
              </dev/null &>/dev/null) &
            echo $! >$SOCAT_PID_FILE
          fi
        }

        if [ ! -d "${config.home.homeDirectory}/.gnupg/socketdir" ]; then
          # On Windows, symlink the directory that contains `S.gpg-agent.ssh` from
          # `wsl-pageant`. `npiperelay` will place `S.gpg-agent.extra` in this directory.
          # This will be the exact same locations that files are placed when running on
          # Linux, so that remote forwarding works.
          ${pkgs.coreutils}/bin/ln -s "/mnt/c/wsl-pageant" \
            "${config.home.homeDirectory}/.gnupg/socketdir"
        fi

        # When setting up GPG forwarding to WSL on Windows, get `npiperelay` (see comment in
        # `_run_npiperelay`) and `gpg4win`. Add a shortcut that runs at startup that will
        # launch the gpg-agent:
        #
        #   "C:\Program Files (x86)\GnuPG\bin\gpg-connect-agent.exe" /bye

        # Relay the primary GnuPG socket to `~/.gnupg/S.gpg-agent` which will be used by the
        # GPG agent.
        _run_npiperelay "${config.home.homeDirectory}/.gnupg/socat-gpg.pid" \
          "${config.home.homeDirectory}/.gnupg/S.gpg-agent" \
          "C:/Users/David/AppData/Roaming/gnupg/S.gpg-agent"

        # Relay the extra GnuPG socket to `~/.gnupg/S.gpg-agent.extra` which will be forwarded
        # to remote SSH hosts.
        _run_npiperelay "${config.home.homeDirectory}/.gnupg/socat-gpg-extra.pid" \
          "${config.home.homeDirectory}/.gnupg/socketdir/S.gpg-agent.extra" \
          "C:/Users/David/AppData/Roaming/gnupg/S.gpg-agent.extra"

        # When setting up SSH forwarding to WSL on Windows, get `wsl-ssh-pageant`
        # (https://github.com/benpye/wsl-ssh-pageant) and place it in `C:\wsl-pageant`. Add a
        # `wsl-pageant.vbs` script to the startup directory with the following contents:
        #
        # ```vbs
        # Set objFile = WScript.CreateObject("Scripting.FileSystemObject")
        # if objFile.FileExists("c:\wsl-pageant\S.gpg-agent.ssh") then
        #     objFile.DeleteFile "c:\wsl-pageant\S.gpg-agent.ssh"
        # end if
        # Set objShell = WScript.CreateObject("WScript.Shell")
        # objShell.Run( _
        #   "C:\wsl-pageant\wsl-ssh-pageant-amd64.exe --wsl c:\wsl-pageant\S.gpg-agent.ssh"), _
        #   0, True
        # ```

        # This file should exist because of `wsl-ssh-pageant`.
        export SSH_AUTH_SOCK = "${config.home.homeDirectory}/.gnupg/socketdir/S.gpg-agent.ssh"
      '' else ''
        if [ ! -d "${config.home.homeDirectory}/.gnupg/socketdir" ]; then
          # On Linux, symlink this to the directory where the sockets are placed by the GPG
          # agent.
          # This needs to exist for the remote forwarding.
          ${pkgs.coreutils}/bin/ln -s "$(${pkgs.coreutils}/bin/dirname \
                    "$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-socket)")" \
            "${config.home.homeDirectory}/.gnupg/socketdir"
        fi

        export GPG_TTY=$(tty)
        export SSH_AUTH_SOCK="$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)"
        if [ -z $SSH_CONNECTION ] && [ -z $SSH_CLIENT ]; then
          # Don't start the `gpg-agent` for remote connections. The sockets from the local
          # host will be forwarded and picked up by the gpg client.
          ${pkgs.gnupg}/bin/gpgconf --launch gpg-agent
        fi
      ''
    ) + ''
      # Bind keys for Surface and other strange keyboards.
      bindkey "^?" backward-delete-char
      bindkey "^W" backward-kill-word
      bindkey "^H" backward-delete-char
      bindkey "^U" backward-kill-line
      bindkey "[3~" delete-char
      bindkey "[7~" beginning-of-line
      bindkey "[1~" beginning-of-line
      bindkey "[8~" end-of-line
      bindkey "[4~" end-of-line

      # Disable control flow, allows CTRL+S to be used.
      stty -ixon

      # Treat the '!' character specially during expansion.
      setopt BANG_HIST
      # Write to the history file immediately, not when the shell exits.
      setopt INC_APPEND_HISTORY
      # Expire duplicate entries first when trimming history.
      setopt HIST_EXPIRE_DUPS_FIRST
      # Delete old recorded entry if new entry is a duplicate.
      setopt HIST_IGNORE_ALL_DUPS
      # Do not display a line previously found.
      setopt HIST_FIND_NO_DUPS
      # Don't record an entry starting with a space.
      setopt HIST_IGNORE_SPACE
      # Don't write duplicate entries in the history file.
      setopt HIST_SAVE_NO_DUPS
      # Remove superfluous blanks before recording entry.
      setopt HIST_REDUCE_BLANKS
      # Don't execute immediately upon history expansion.
      setopt HIST_VERIFY

      # Enable fasd integration.
      if [ "${pkgs.fasd}/bin/fasd" -nt "${config.xdg.cacheHome}/zsh/fasd" -o \
          ! -s "${config.xdg.cacheHome}/zsh/fasd" ]; then
        ${pkgs.fasd}/bin/fasd --init posix-alias zsh-hook zsh-ccomp \
          zsh-ccomp-install >| "${config.xdg.cacheHome}/fasd"
      fi

      # Define `fasd_cd` command.
      fasd_cd() {
        if [ $# -le 1 ]; then
          ${pkgs.fasd}/bin/fasd "$@"
        else
          local _fasd_ret = "$(${pkgs.fasd}/bin/fasd -e echo "$@")"
          [ -z "$_fasd_ret" ] && return
          [ -d "$_fasd_ret" ] && cd "$_fasd_ret" || echo "$_fasd_ret"
        fi
      }

      # If running in Neovim terminal mode then don't let us launch Neovim.
      if [ -n "$NVIM_LISTEN_ADDRESS" ]; then
        alias nvim = 'echo "No nesting!"'
      fi

      # Use CTRL + ' ' to accept current autosuggestion.
      bindkey '^ ' autosuggest-accept

      # Enable yank, change, and delete whole line with 'Y', 'cc', and 'dd'.
      bindkey -M vicmd 'Y' vi-yank-whole-line

      # Enable undo/redo with `u`/`U`.
      bindkey -M vicmd 'u' undo
      bindkey -M vicmd 'U' redo

      # Comment out the command with `gcc` (like vim-commentary).
      bindkey -M vicmd 'gcc' vi-pound-insert

      # Use editor to edit command line with `CTRL-V`.
      autoload -U edit-command-line
      zle -N edit-command-line
      bindkey -M vicmd '^V' edit-command-line

      # Disable Ex mode with ':'.
      bindkey -rM vicmd ': '
    '';
    plugins = [
      {
        # Suggest using shorter aliases.
        name = "you-should-use";
        src = builtins.fetchGit {
          url = "https://github.com/MichaelAquilina/zsh-you-should-use.git";
          ref = "master";
          rev = "e80ea3462514be31c43b65886105ac051114456e";
        };
      }
      {
        # Install and keep NVM up-to-date.
        name = "zsh-nvm";
        src = builtins.fetchGit {
          url = "https://github.com/lukechilds/zsh-nvm.git";
          ref = "master";
          rev = "9ae1115e76a7ff1e8fcb42e530c196834609f76d";
        };
      }
      {
        # Additional completion definitions.
        name = "zsh-completions";
        src = builtins.fetchGit {
          url = "https://github.com/zsh-users/zsh-completions.git";
          ref = "master";
          rev = "b512d57b6d0d2b85368a8068ec1a13288a93d267";
        };
      }
      {
        # Fish-like fast/unobtrustive autosuggestions.
        name = "zsh-autosuggestions";
        src = builtins.fetchGit {
          url = "https://github.com/zsh-users/zsh-autosuggestions.git";
          ref = "master";
          rev = "43f3bc4010b2c697d2252fdd8b36a577ea125881";
        };
      }
      {
        # Faster syntax highlighting.
        name = "fast-syntax-highlighting";
        src = builtins.fetchGit {
          url = "https://github.com/zdharma/fast-syntax-highlighting.git";
          ref = "master";
          rev = "581e75761c6bea46f2233dbc422d37566ce43f5e";
        };
      }
      {
        # Git fuzzy commands.
        name = "forgit";
        src = builtins.fetchGit {
          url = "https://github.com/wfxr/forgit.git";
          ref = "master";
          rev = "106c1f86d16ba7aa3878f67952c5a0ac9d80e5b0";
        };
      }
      {
        # Jumping back directories.
        name = "bd";
        src = builtins.fetchGit {
          url = "https://github.com/Tarrasch/zsh-bd.git";
          ref = "master";
          rev = "d4a55e661b4c9ef6ae4568c6abeff48bdf1b1af7";
        };
      }
    ];
    sessionVariables =
      {
        # Enable true colour and use a 256-colour terminal.
        "COLORTERM" = "truecolor";
        "TERM" = "xterm-256color";
        # 10ms for key sequences
        "KEYTIMEOUT" = "1";
        # Enable persistent REPL history for node.
        "NODE_REPL_HISTORY" = "${config.xdg.cacheHome}/node/history";
        # Use sloppy mode by default, matching web browsers.
        "NODE_REPL_MODE" = "sloppy";
        # Allow Vagrant to access Windows outside of WSL.
        "VAGRANT_WSL_ENABLE_WINDOWS_ACCESS" = "1";
        # Set a cache directory for zsh.
        "ZSH_CACHE_DIR" = "${config.xdg.cacheHome}/zsh";
        # Configure autosuggestions.
        "ZSH_AUTOSUGGEST_USE_ASYNC" = "1";
        "ZSH_AUTOSUGGEST_ACCEPT_WIDGETS" = "()";
      } // lib.attrsets.optionalAttrs config.veritas.david.dotfiles.isNonNixOS {
        # Needed for `home-manager switch` to work.
        "NIX_PATH" = "${config.home.homeDirectory}/.nix-defexpr/channels\${NIX_PATH:+:}$NIX_PATH";
      };
    shellAliases = {
      # Make `rm` prompt before removing more than three files or removing recursively.
      "rm" = "${pkgs.coreutils}/bin/rm -i";
      # Aliases that make commands colourful.
      "grep" = "${pkgs.gnugrep}/bin/grep --color=auto";
      "fgrep" = "${pkgs.gnugrep}/bin/fgrep --color=auto";
      "egrep" = "${pkgs.gnugrep}/bin/egrep --color=auto";
      # Aliases for `cat` to `bat`.
      "cat" = "${pkgs.bat}/bin/bat --theme=TwoDark --paging=never -p";
      # Aliases for `ls` to `exa`.
      "ls" = "${pkgs.exa}/bin/exa";
      "dir" = "${pkgs.exa}/bin/exa";
      "ll" = "${pkgs.exa}/bin/exa -alF";
      "vdir" = "${pkgs.exa}/bin/exa -l";
      "la" = "${pkgs.exa}/bin/exa -a";
      "l" = "${pkgs.exa}/bin/exa -F";
      # Various aliases for `fasd`.
      "a" = "${pkgs.fasd}/bin/fasd -a";
      "s" = "${pkgs.fasd}/bin/fasd -si";
      "d" = "${pkgs.fasd}/bin/fasd -d";
      "f" = "${pkgs.fasd}/bin/fasd -f";
      "sd" = "${pkgs.fasd}/bin/fasd -sid";
      "sf" = "${pkgs.fasd}/bin/fasd -sif";
      "z" = "fasd_cd -d";
      "zz" = "fasd_cd -d -i";
      "v" = "${pkgs.fasd}/bin/fasd -f -e vim";
      # Extra Git subcommands for GitHub.
      "git" = "${pkgs.gitAndTools.hub}/bin/hub";
      # Build within a docker container with a rust and musl toolchain.
      "rust-musl-builder" =
        "${pkgs.docker}/bin/docker run --rm -it -v \"$PWD\":/home/rust/src " + "ekidd/rust-musl-builder:stable";
      # Use this alias to make GPG need to unlock the key. `gpg-update-ssh-agent` would also want
      # to unlock the key, but the pinentry prompt mangles the terminal with that command.
      "gpg-unlock-key" =
        "echo 'foo' | ${pkgs.gnupg}/bin/gpg -o /dev/null --local-user " + "${config.programs.git.signing.key} -as -";
      # Use this alias to make the GPG agent relearn what keys are connected and what keys they
      # have.
      "gpg-relearn-key" = "${pkgs.gnupg}/bin/gpg-connect-agent 'scd serialno' 'learn --force' /bye";
      # > Set the startup TTY and X-DISPLAY variables to the values of this session. This command
      # > is useful to direct future pinentry invocations to another screen. It is only required
      # > because there is no way in the ssh-agent protocol to convey this information.
      "gpg-update-ssh-agent" = "${pkgs.gnupg}/bin/gpg-connect-agent updatestartuptty /bye";
      # Use this alias to make sure everything is in working order. Need to unlock twice - if
      # `gpg-update-ssh-agent` called with an locked key then it will prompt for it to be unlocked
      # in a way that will mangle the terminal, therefore we need to unlock before this.
      "gpg-refresh" = "gpg-relearn-key && gpg-unlock-key && gpg-update-ssh-agent";
      # Fairly self explanatory, prints the current external IP address.
      "what-is-my-ip" = "${pkgs.dnsutils}/bin/dig +short myip.opendns.com @resolver1.opendns.com";
      # `<command> | sprunge` will make a quick link to send.
      "sprunge" = "${pkgs.curl}/bin/curl -F 'sprunge=<-' http://sprunge.us";
      # Stop printing the version number on gdb startup.
      "gdb" = "gdb -q";
    };
  };
}

# vim:foldmethod=marker:foldlevel=0:ts=2:sts=2:sw=2:nowrap