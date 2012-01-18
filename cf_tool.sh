#!/bin/bash

#Authorization test
auth_test() {
    curl -D - -H "X-Auth-Key: $1" -H "X-Auth-User: $2" $3 &>/tmp/cf_test.tmp
	TOKEN=$(grep -E '(X-Auth-Token:)' /tmp/cf_test.tmp)
    SURL=$(grep -E '(X-Storage-Url:)' /tmp/cf_test.tmp | awk '{print $2}' | sed -e 's/
	rm /tmp/cf_test.tmp
}

#List containers
list_containers() {
    curl -X GET  -H "$TOKEN" $SURL
}

#List Objects in a specified container
list_objects() {
    curl -X GET  -H "$TOKEN" $SURL/$1
}

delete_objects() {
    curl -X GET  -H "$TOKEN" $SURL/$1 > /tmp/cf_objects
    while read line; do
        curl -X DELETE  -H "$TOKEN" $SURL/$1/$line #Delete Objects
    done < /tmp/cf_objects
    curl -X DELETE  -H "$TOKEN" $SURL/$1 #Delete Container
    rm /tmp/cf_objects
}

#Command Line Parser
while getopts "c:k:u:123:4:" opt; do
  case $opt in
    c) case $OPTARG in
         uk|UK) URL="https://lon.auth.api.rackspacecloud.com/v1.0";;
         us|US) URL="https://auth.api.rackspacecloud.com/v1.0";;
            *) echo "$OPTARG is an invalid argument"
               exit 1;;
       esac;;
    k) KEY=$OPTARG;;
    u) USER=$OPTARG;;
    1) auth_test $KEY $USER $URL #Auth Test
       echo $TOKEN
	   echo $SURL;;
    2) auth_test $KEY $USER $URL #List Containers
       list_containers;;
    3) auth_test $KEY $USER $URL #List Objects Container
       CONTAINER=$OPTARG
       list_objects $CONTAINER;;
    4) auth_test $KEY $USER $URL #Delete Objects and container
       CONTAINER=$OPTARG
       delete_objects $CONTAINER;;
  esac
done