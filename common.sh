#!/usr/bin/env bash


directory_exists() {
  dir=$1
  if [[ -d $dir ]]; then
    return 0
  fi
  return 1
}

command_exists() {
  cmd=$1
  if ! command -v $cmd &> /dev/null
  then
    echo "($cmd) does not exist on you machine, please make sure to install it"
    exit
  fi
}

create_directory() {
  dir=$1
  if ! directory_exists $dir; then
    mkdir -p $dir
  fi
}

call_and_log() {
  func=$1
  eval $func 2>&1 | tee $LOGS/$func.log
}

call_silent() {
  func=$1
  eval $func >>$LOGS/$func.log 2>&1 
}

log() {
  echo "  [-] $1"
}
