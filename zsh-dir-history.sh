zmodload zsh/datetime

setopt inc_append_history

ZSH_DIR_HISTORY_TTY=`tty`
ZSH_DIR_HISTORY_HISTDIR=$HOME/.zsh_dir_history
# per terminal history file uses "private-$tty" where $tty is e.g. /dev/ttys097 with / replaced with %)
ZSH_DIR_HISTORY_PRIVATE_HISTFILE=$ZSH_DIR_HISTORY_HISTDIR/private-${ZSH_DIR_HISTORY_TTY//\//%}
ZSH_DIR_HISTORY_SHARED_HISTFILE=$ZSH_DIR_HISTORY_HISTDIR/shared
ZSH_DIR_HISTORY_LOGFILE=$ZSH_DIR_HISTORY_HISTDIR/zsh_dir_history.log

# histfile to use when per-dir history is exhausted
ZSH_DIR_HISTORY_NONDIR_HISTFILE=$ZSH_DIR_HISTORY_PRIVATE_HISTFILE
touch $ZSH_DIR_HISTORY_NONDIR_HISTFILE

ZSH_DIR_HISTORY_INITIALIZED=0

mkdir -p $ZSH_DIR_HISTORY_HISTDIR &> /dev/null


# Generates a new history for the current directory
function generate_history() {
  # expand $PWD and remove symlinks
  local tmp_pwd=${PWD:A}
  # this will be the per-dir filename. replace all '/' with '%' in $tmp_pwd
  local cwd_name=${tmp_pwd//\//%}
  # this is the full path to the per-dir HISTFILE
  local cwd_histfile=${ZSH_DIR_HISTORY_HISTDIR}/${cwd_name}
  touch $cwd_histfile

  # update old HISTFILE with curent history list
  fc -AI

  # erase history list
  fc -P
  fc -p $ZSH_DIR_HISTORY_HISTDIR/tmp

  # populate history list with the non-dir file
  HISTFILE=$ZSH_DIR_HISTORY_NONDIR_HISTFILE
  fc -R

  # append dir-specific history list
  HISTFILE=$cwd_histfile
  fc -R
}

function llog() {
    echo "in llog"
}

function new_prompt_setup() {
    if [[ "${ZSH_DIR_HISTORY_INITIALIZED}" == "1" ]]; then
        return
    fi
    generate_history
    ZSH_DIR_HISTORY_INITIALIZED=1
}

last_command=""
# Append to common history file
function log_command() {
  # [[ "${1}" = \ * ]] && [[ "$HISTCONTROL" =~ "ignorespace" ]] && return
  # if [[ "${1}" != ${~HISTORY_IGNORE} ]]; then
  #   [[ "${1}" == "$last_command" ]] && [[ "$HISTCONTROL" =~ "ignoredups" ]] && return
  # fi
  # last_command="${1}"
  echo -n ": ${EPOCHSECONDS}:0;${1}\n" >> $ZSH_DIR_HISTORY_NONDIR_HISTFILE
}

# Call generate_history() everytime the directory is changed
chpwd_functions=(${chpwd_functions[@]} "generate_history")
# chpwd_functions=("generate_history")

# Call log_command() everytime a command is executed
preexec_functions=(${preexec_functions[@]} "log_command")
# preexec_functions=("log_command")

# Call generate_history() everytime the user opens a prompt
precmd_functions=(${precmd_functions[@]} "new_prompt_setup")
# precmd_functions=(${precmd_functions[@]} "llog")
# precmd_functions=("generate_history")
