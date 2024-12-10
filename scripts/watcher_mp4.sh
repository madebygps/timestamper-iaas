#!/bin/bash

INPUT_DIR="/volume1/shared-mount/mp4s"
LOG_DIR = "volume1/shared-mount/logs"
LOG_FILE = "$LOG_FILE/watcher.log"
PID_FILE = "/var/run/mp4_watcher.pid"
SCRIPT_NAME = "MP4 Watcher"


setup_logging()
{ 
  mkdir -p "$LOG_DIR" 

  if [ -f "$LOG_FILE" ] && [ $(stat -f%z "$LOG_FILE") -gt 10485760 ]; then
    mv "$LOG_FILE" "$LOG_FILE.old"
  fi
}



log()
{
  local level=$1
  local message=$2
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}


check_dependencies() {
  for cmd in inotifywait ffmpeg; do
    if ! command -v $cmd &> /dev/null; then
      log "ERROR" "$cmd is requiered but not installed."
      exit 1 
    fi
  done
}


start_daemon()
{
  setup_logging
  check_dependencies

  if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    log "ERROR" "$SCRIPT_NAME is already running!"
    exit 1 
  fi

  if ! mkdir -p "$INPUT_DIR"; then
    log "ERROR" "Failed to create input directory: $INPUT_DIR"
  fi


  log "INFO" "Starting $SCRIPT_NAME daemon"
  echo $$ > "$PID_FILE"


  inotifywait -m -e create -e moved_to "$input_dir" 2>> "$LOG_FILE" | while read -r line; do

      if [[ "$line" =~ "Setting up watcher." ]] || [[ "$line" =~ "Watcher established." ]]; then
          continue
      fi
    
      read -r directory event filename <<< "$line"
   
      if [ -z "$directory" ] || [ -z "$event" ] || [ -z "$filename" ]; then
          echo "Skipping invalid line (missing component)"
          continue
      fi
    
      log "Detected new file: $filename"
      if [[ "$filename" =~ \.mp4$ ]]; then
        log "INFO" "Processing MP4 file: $filename"
        ./extract_audio.sh "$input_dir/$filename"
      fi
  done
}


stop_daemon(){
  if [ -f "$PID_FILE" ]; then
    log "INFO" "Stopping $SCRIPT_NAME daemon."
    kill $(cat "$PID_FILE")
    rm "$PID_FILE"
  else
    log "WARNING" "$SCRIPT_NAME is not running."
  fi
}


case "$1" in
  start)
    start_daemon
    ;;
  stop)
    stop_daemon
    ;;
  restart)
    stop_daemon
    sleep 1 
    start_daemon
    ;;
  status)
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
      echo "$SCRIPT_NAME is running"
    else
      echo "$SCRIPT_NAME" is not running
    fi
    ;;;
  *)
    echo "Usage $0 {start|stop|restart|status}"
    exit 1 
    ;;
esac

exit 0
