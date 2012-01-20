#!/bin/bash
source ./creds.inc
function strip() { echo $1 | tr -d "\r"; }

# From Jordan Callicoat
# this works everywhere
oIFS=$IFS
IFS=`echo -e '\n'`

headers=`curl -s -i -H "X-Auth-User: ${username}" -H "X-Auth-Key: ${api_key}" \
           https://auth.api.rackspacecloud.com/v1.0`
url=$(strip `echo ${headers} | awk '/X-Storage-Url:/ {print $2}'`)
token=$(strip `echo ${headers} | awk '/X-Auth-Token:/ {print $2}'`)
status=$(strip `echo ${headers} | awk '/HTTP\/1\.1/ {print $2}'`)

IFS=$oIFS

echo ${url}
echo ${token}
echo ${status}
