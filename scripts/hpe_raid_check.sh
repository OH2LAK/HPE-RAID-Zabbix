#!/bin/bash
# HPE Smart Array RAID health check
# Part of: hpe-raid-zabbix
# https://github.com/OH2LAK/hpe-raid-zabbix
#
# NOTE: ssacli is intentionally called with its FULL PATH (/usr/sbin/ssacli).
# On most distros ssacli lives in /usr/sbin, not /usr/bin. If this script is
# called via sudo with NOPASSWD and the sudoers rule uses a different path
# than what is actually invoked here, sudo will silently fall back to
# requiring a password and the check will fail with no useful error.
# Keep this path and the path in the sudoers file identical.

SSACLI="/usr/sbin/ssacli"
SLOT="${1:-0}"
STATUS="OK"
ISSUES=""

# Check logical drives
LD=$($SSACLI ctrl slot=$SLOT ld all show status 2>/dev/null)
if echo "$LD" | grep -qiE "failed|degraded"; then
    STATUS="CRITICAL"
    ISSUES+="$(echo "$LD" | grep -iE 'failed|degraded' | xargs) "
fi

# Check physical drives
PD=$($SSACLI ctrl slot=$SLOT pd all show status 2>/dev/null)
if echo "$PD" | grep -qiE "failed|predictive failure"; then
    STATUS="CRITICAL"
    ISSUES+="$(echo "$PD" | grep -iE 'failed|predictive' | xargs) "
fi

# Check cache / battery
CACHE=$($SSACLI ctrl slot=$SLOT show detail 2>/dev/null)
if echo "$CACHE" | grep -qiE "battery/capacitor status: failed"; then
    STATUS="WARNING"
    ISSUES+="Battery/Cache failed "
fi

echo "${STATUS}${ISSUES:+: $ISSUES}"
