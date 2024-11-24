#!/bin/bash

# Configuration variables

INPUT_DIR="/volume1/shared-mount/mp4s"
LOG_DIR = "volume1/shared-mount/logs"
LOG_FILE = "$LOG_FILE/watcher.log"
PID_FILE = "/var/run/mp4_watcher.pid"
SCRIPT_NAME = "MP4 Watcher"

# Logging setup 
setup_logging()
{ 
  mkdir -p "$LOG_DIR" 
  # Rotate logs if file exceeds 10 mb
  if [ -f "$LOG_FILE" ] && [ $(stat -f%z "$LOG_FILE") -gt 10485760 ]; then
    mv "$LOG_FILE" "$LOG_FILE.old"
  fi
}

# Logging function

log()
{
  local level=$1
  local message=$2
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Check dependencies 
check_dependencies() {
  for cmd in inotifywait ffmpeg; do
    if ! command -v $cmd &> /dev/null; then
      log "ERROR" "$cmd is requiered but not installed."
      exit 1 
    fi
  done
}

# Main daemon function 
start_daemon()
{
  setup_logging
  check_dependencies

  # Check if already running
  if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    log "ERROR" "$SCRIPT_NAME is already running!"
    exit 1 
  fi

  # Create input directory if it doesn't exist
  if ! mkdir -p "$INPUT_DIR"; then
    log "ERROR" "Failed to create input directory: $INPUT_DIR"
  fi

  # Start the daemon
  log "INFO" "Starting $SCRIPT_NAME daemon"
  echo $$ > "$PID_FILE"

  # Monitor directory
  inotifywait -m -e create -e moved_to "$input_dir" 2>> "$LOG_FILE" | while read -r line; do
    # Skip the setup messages
      if [[ "$line" =~ "Setting up watcher." ]] || [[ "$line" =~ "Watcher established." ]]; then
          continue
      fi
    
     # Parse the line into components
      read -r directory event filename <<< "$line"
    
      # Skip invalid lines
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

# Stop daemon function 
stop_daemon(){
  if [ -f "$PID_FILE" ]; then
    log "INFO" "Stopping $SCRIPT_NAME daemon."
    kill $(cat "$PID_FILE")
    rm "$PID_FILE"
  else
    log "WARNING" "$SCRIPT_NAME is not running."
  fi
}

# Command line interface
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
