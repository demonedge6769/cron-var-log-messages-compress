#!/bin/sh

LOGFILE="/var/log/messages"
MIN_SIZE=$((400 * 1024 * 1024))   # 500 MB
DATE=$(date +%d%m%Y)
LOCKFILE="/var/run/rotate_messages.lock"

# Detect if running from cron (no TTY)
IS_CRON=1
[ -t 1 ] && IS_CRON=0

# Prevent concurrent runs
exec 9>"$LOCKFILE" || exit 1
flock -n 9 || exit 0

# Exit if file does not exist
if [ ! -f "$LOGFILE" ]; then
    [ "$IS_CRON" -eq 0 ] && echo "Log file does not exist: $LOGFILE"
    exit 0
fi

# Get file size in bytes
FILESIZE=$(stat -c %s "$LOGFILE" 2>/dev/null || wc -c < "$LOGFILE")

# If file is smaller than 500 MB
if [ "$FILESIZE" -lt "$MIN_SIZE" ]; then
    if [ "$IS_CRON" -eq 0 ]; then
        # Human‑readable size
        HSIZE=$(du -h "$LOGFILE" | awk '{print $1}')
        echo "File size of $LOGFILE is $HSIZE (less than 500MB). No rotation needed."
    fi
    exit 0
fi

# Find next available suffix
SUFFIX=1
while [ -e "${LOGFILE}-${DATE}-${SUFFIX}.gz" ] || \
      [ -e "${LOGFILE}-${DATE}-${SUFFIX}" ]; do
    SUFFIX=$((SUFFIX + 1))
done

ARCHIVE="${LOGFILE}-${DATE}-${SUFFIX}"

# Rotate
cp -p "$LOGFILE" "$ARCHIVE" || exit 1
: > "$LOGFILE"
gzip "$ARCHIVE"

[ "$IS_CRON" -eq 0 ] && echo "Rotated $LOGFILE -> ${ARCHIVE}.gz"