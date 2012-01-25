#!/bin/bash

function strip() { echo $1 | tr -d "\r"; }

#Authorization
get_auth_token() {
    # From Jordan Callicoat
    # this works everywhere
    oIFS=$IFS
    IFS=`echo -e '\n'`
    headers=`curl -s -i -H "X-Auth-User: $USER" -H "X-Auth-Key: $KEY" $URL`
    surl=$(strip `echo ${headers} | awk '/X-Storage-Url:/ {print $2}'`)
    token=$(strip `echo ${headers} | awk '/X-Auth-Token:/ {print $2}'`)
    status=$(strip `echo ${headers} | awk '/HTTP\/1\.1/ {print $2}'`)
    IFS=$oIFS
}

#List containers
list_containers() {
    curl -X GET  -H "X-Auth-Token: $token" $surl
}

#List Objects in a specified container
list_objects() {

    LIST=0
    curl -X GET  -H "$TOKEN" $SURL/$1 > /tmp/cf_objects$LIST
    LINES=$(wc -l /tmp/cf_objects$LIST | awk '{print $1}')

    while [ $LINES -eq 10000 ]
    do
        curl -X GET  -H "$TOKEN" $SURL/$1?marker=$MARKER > /tmp/cf_objects$LIST
        MARKER=$(tail -n 1 /tmp/cf_objects$LIST)
        LINES=$(wc -l /tmp/cf_objects$LIST | awk '{print $1}')
        LIST=$[$LIST+1]
    done
    cat /tmp/cf_objects* > ./Object_list.txt
    rm /tmp/cf_objects*
    echo "A list of objects has been saved in the current directory."
}

#Delete all objects inside a container and then delete the container
container_kill() {
    while [ `curl -X GET -H "X-Auth-Token: $token" $surl/$1 | wc -l` -gt 0 ]; do
        curl -X GET -H "X-Auth-Token: $token" $surl/$1 > deletethese.lst
        while read LINE; do
            LINE=`echo "$LINE" | sed 's/ /%20/g'`
            LINE=`echo "$LINE" | sed 's/,/%2C/g'`
            curl -X DELETE -H "X-Auth-Token: $token" $surl/$1/$LINE &
            echo $LINE
        done < deletethese.lst
    done
curl -X DELETE -H "X-Auth-Token: $token" $surl/$1
rm deletethese.lst
}

create_container() {
    curl -X PUT  -H "$TOKEN" $SURL/$1
}

usage() {
    cat << EOF 
Usage: ./cf_tool.sh [-c US or UK] [-u username] [-k apikey] [-1234X]

Examples:

Authorization test:
    ./cf_tool.sh -c US -u username -k api_key -0
    
List containers:
    ./cf_tool.sh -c US -u username -k api_key -1

Delete container:
    ./cf_tool.sh -c US -u username -k api_key -X container_name
EOF
    exit
}

#Command Line Parser
while getopts "c:k:u:123:X:4:h" opt; do
    case $opt in
        c) case $OPTARG in
            uk|UK) URL="https://lon.auth.api.rackspacecloud.com/v1.0";;
            us|US) URL="https://auth.api.rackspacecloud.com/v1.0";;
                *) echo "$OPTARG is an invalid argument"
                exit 1;;
                esac;;
        h) usage;;
        k) KEY=$OPTARG;;
        u) USER=$OPTARG;;
        1)  get_auth_token $KEY $USER $URL #Auth Test
            echo -e "Storage URL:\n$surl\n"
            echo -e "Authorization token:\n$token\n"
            if [ $status -eq "204" ]; then
                    echo "Your request was successful! Status code $status"
                else
                    echo "There was a problem! Status code $status"
            fi;;
        2)  get_auth_token $KEY $USER $URL #List Containers
            list_containers;;
        3)  get_auth_token $KEY $USER $URL #List Objects Container
            CONTAINER=$OPTARG
            list_objects $CONTAINER;;
        X)  get_auth_token $KEY $USER $URL #Delete Objects and container
            CONTAINER=$OPTARG
            container_kill $CONTAINER;;
        4)  get_auth_token $KEY $USER $URL #Create Container
            CONTAINER=$OPTARG
            create_container $CONTAINER;;
    esac
done
