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

# vim:foldmethod=marker:foldlevel=0:ts=2:sts=2:sw=2:nowrap
