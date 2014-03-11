#!/bin/bash
# Copyright 2014 David Spencer, Baildon, West Yorkshire, U.K.
# All rights reserved.  For licence details, see the file 'LICENCE'.
#-------------------------------------------------------------------------------
# procfunctions.sh - processing functions for slackrepo
#   process_item
#   process_remove
#-------------------------------------------------------------------------------
# Note that we set the variable $ITEMPATH (upper case) so that other functions
# called recursively (which get $itempath as an argument) can test whether they
# are dealing with the top level item.
#-------------------------------------------------------------------------------

function process_item
# Either build or remove an item
# $1 = itempath
# Sets global variable ITEMPATH so the top level item can be identified
# Return status: always 0 -- if an error occurs, exit with status 4
{
  local ITEMPATH="$1"
  local PRGNAM=${ITEMPATH##*/}

  echo ""
  log_start "$ITEMPATH"

  case "$PROCMODE" in
  'add' | 'rebuild' | 'test')
    build_with_deps $ITEMPATH
    ;;
  'update')
    if [ -d $SR_GITREPO/$ITEMPATH/ ]; then
      build_with_deps $ITEMPATH
    else
      process_remove $ITEMPATH
    fi
    ;;
  'remove')
    process_remove $ITEMPATH
    ;;
  *)
    log_error "$(basename $0): Unrecognised PROCMODE = $PROCMODE" ; exit 4 ;;
  esac

  return
}

#-------------------------------------------------------------------------------

function process_remove
# Remove an item from the package repository and the source repository
# $1 = itempath
# Return status:
# 0 = item removed
# 1 = item was skipped
{
  local ITEMPATH="$1"
  local PRGNAM=${ITEMPATH##*/}

  # Don't remove if this is an update and it's marked to be skipped
  if [ "$PROCMODE" = 'update' ]; then
    if hint_skipme $ITEMPATH; then
      SKIPPEDLIST="$SKIPPEDLIST $ITEMPATH"
      return 1
    fi
  fi

  if [ "$UPDATEDRYRUN" = 'y' ]; then
    log_important "$ITEMPATH would be removed"
    echo "$ITEMPATH would be removed" >> $SR_UPDATEFILE
  else
    log_important "Removing $ITEMPATH"
    rm -rf $SR_PKGREPO/$ITEMPATH/
    rm -rf $SR_SRCREPO/$ITEMPATH/ $SR_SRCREPO/${ITEMPATH}_BAD/
    echo "$ITEMPATH: Removed. NEWLINE" >>$SR_CHANGELOG
  fi
  return
}
