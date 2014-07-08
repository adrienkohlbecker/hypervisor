#!/bin/bash
test -e /usr/local/lib/bash-framework && source /usr/local/lib/bash-framework || (echo "Could not load bash-framework" 1>&2; exit 1)

################################
#        SCRIPT CONFIG         #
################################

# Threshold of deleted files over which to show an error
# Useful in case of mass deletion by human error / missing device
DEL_THRESHOLD=50

# Destination email
EMAIL_TO="root"

# Email subject prefix
EMAIL_SUBJECT_PREFIX="[$(hostname -s)] $NAME - "

################################
#          ACTUAL JOB          #
###############################@

function dogevent_log()
{
  dogevent --title "$NAME - $1" \
    --file "$TMP_OUTPUT" \
    --alert_type "${2:-info}" \
    --priority "${3:-normal}" \
    --tag "application:$NAME" \
    --host "$(hostname)" \
    --aggregation_key "$NAME - $1"
}

must_run_as_root

br
log "snapraid sync started."

run "snapraid diff 2>&1"

DEL_COUNT=$(grep '[0-9]\{1,\} removed$' "$TMP_OUTPUT" | sed 's/ \+/ /g' | cut -d ' ' -f2)
ADD_COUNT=$(grep '[0-9]\{1,\} added$' "$TMP_OUTPUT" | sed 's/ \+/ /g' | cut -d ' ' -f2)
MOVE_COUNT=$(grep '[0-9]\{1,\} moved$' "$TMP_OUTPUT" | sed 's/ \+/ /g' | cut -d ' ' -f2)
COPY_COUNT=$(grep '[0-9]\{1,\} copied$' "$TMP_OUTPUT" | sed 's/ \+/ /g' | cut -d ' ' -f2)
UPDATE_COUNT=$(grep '[0-9]\{1,\} updated$' "$TMP_OUTPUT" | sed 's/ \+/ /g' | cut -d ' ' -f2)
RESTORE_COUNT=$(grep '[0-9]\{1,\} restored$' "$TMP_OUTPUT" | sed 's/ \+/ /g' | cut -d ' ' -f2)

log "SUMMARY of changes - Added [$ADD_COUNT] - Deleted [$DEL_COUNT] - Moved [$MOVE_COUNT] - Copied [$COPY_COUNT] - Updated [$UPDATE_COUNT] - Restored [$RESTORE_COUNT]"

# Check if files have changed
if [ "$DEL_COUNT" -gt 0 -o "$ADD_COUNT" -gt 0 -o "$MOVE_COUNT" -gt 0 -o "$UPDATE_COUNT" -gt 0 -o "$RESTORE_COUNT" -gt 0 ]; then
  # YES, check if number of deleted files exceed DEL_THRESHOLD
  if [ "$DEL_COUNT" -gt $DEL_THRESHOLD ]; then
    # YES, lets inform user and not proceed with the sync just in case
    log "Number of deleted files ($DEL_COUNT) exceeded threshold ($DEL_THRESHOLD)."
    log "NOT proceeding with sync job. Please run sync manually if this is not an error condition."
    mail -s "$EMAIL_SUBJECT_PREFIX WARNING - Number of deleted files ($DEL_COUNT) exceeded threshold ($DEL_THRESHOLD)" "$EMAIL_TO" < "$TMP_OUTPUT"
    dogevent_log "Number of deleted files exceeded threshold" "error"
    exit 1
  else
    # NO, delete threshold not reached, lets run the sync job
    log "Deleted files ($DEL_COUNT) did not exceed threshold ($DEL_THRESHOLD), proceeding with sync job."
    run "snapraid sync 2>&1"
    dogevent_log "Sync has finished" "success" "low"
    log "Done."
    exit 0
  fi
else
  # NO, so lets log it and exit
  log "No change detected. Nothing to do"
  dogevent_log "Nothing to do" "success" "low"
  exit 0
fi