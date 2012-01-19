#!/bin/bash

#Authorization test
auth_test() {
    curl -D - -H "X-Auth-Key: $1" -H "X-Auth-User: $2" $3 &>/tmp/cf_test.tmp
    TOKEN=$(grep -E '(X-Auth-Token:)' /tmp/cf_test.tmp)
    SURL=$(grep -E '(X-Storage-Url:)' /tmp/cf_test.tmp | awk '{print $2}' | sed -e 's///g')
    rm /tmp/cf_test.tmp
}

#List containers
list_containers() {
    curl -X GET  -H "$TOKEN" $SURL
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
    curl -X GET  -H "$TOKEN" $SURL/$1 > /tmp/cf_objects
    while read line; do
    curl -X DELETE  -H "$TOKEN" $SURL/$1/$line #Delete Objects
    done < /tmp/cf_objects
    curl -X DELETE  -H "$TOKEN" $SURL/$1 #Delete Container
    rm /tmp/cf_objects
}

create_container() {
    curl -X PUT  -H "$TOKEN" $SURL/$1
}

usage() {
    cat << EOF 
How on earth do I use this?
Please fill me in with usage :)
./`basename $0` --wtf
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
        h) usage
           ;;
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
        X) auth_test $KEY $USER $URL #Delete Objects and container
            CONTAINER=$OPTARG
            container_kill $CONTAINER;;
        4) auth_test $KEY $USER $URL #Create Container
            CONTAINER=$OPTARG
            create_container $CONTAINER;;
    esac
done
