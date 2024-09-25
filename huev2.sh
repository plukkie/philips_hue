#!/bin/bash

############################################################
## This script activates lights on the Philips Hue bridge ##
## Bridge API version: v2                                 ##
############################################################

# BEGIN CONSTANTS
huebridge='https://A.B.C.D'
api_key_file='hue_api_key.txt'
off_delay=3600 #seconds
script_interval=20 # Seconds
BK_wipper_ID=430777b5-dd47-481c-9f46-139548276b56
BK_lightstrip_ID=aa371cce-34b0-4a0f-aaf7-2c79fbed6914
Keuken_wipper_ID=47e42e2f-1f63-46f5-a3b3-890e9c908cb7
Keuken_Kast_ID=b69b6407-cf7e-4a66-85ad-ddefc298cebd  # Grouped light ID

BK_All_Bulb_IDs=( "b7d7eb18-4382-4cad-9d1d-b58d49ee70fc" \
                  "0836977d-eb51-44ce-aa99-23139d66920b" \
                  "56221424-7fe9-4a3b-968e-2e338c89320a" \
                  "6807c7f5-ed3e-415b-8753-f8a83a5251b1" \
                  "b67d1feb-46e5-4816-bddb-8da1815df37f" \
                  "d25fe339-443e-404b-aa2d-23e77815f29e" \
                  "e8373324-5ae0-4604-8170-b02356f863f7" )

BK_spot=0836977d-eb51-44ce-aa99-23139d66920b

# END CONSTANTS

function check_lights () {
	
    # declare before function vars:
    # src_lightid=<HUE ID>
    # dst_lightid=<HUE ID of destination light or group>
    # dst=group (optional of dealing with a grouped_light)
    
    header="hue-application-key: "$user
    api_dst_light="light"
    
    # If it is a group, change API
    if [[ $dst == 'group' ]]; then api_dst_light="grouped_light"; fi


	# Get status of src lamp(s)
	#resp_all_lights=`curl -k -s -H "$header" X GET $huebridge/clip/v2/resource/light`
    #echo $resp_all_lights | jq > all_lights.json
    resp=`curl -k -s -H "$header" X GET $huebridge/clip/v2/resource/light/$src_lightid`
    #echo $resp | jq
    #src_rid=`echo $resp | jq -r '.data[] | select(.id == "'"$src_lightid"'") | .owner.rid'` #get ID of src light 
    #echo $src_rid
    #zigbee_data=`curl -k -s -H "$header" X GET $huebridge/clip/v2/resource/zigbee_connectivity/$src_rid`
    
    #echo $zigbee_data | jq
    #echo $resp | jq
    src_on=`echo $resp | jq .data[].on.on` #get status
    src_name=`echo $resp | jq .data[].metadata.name` #get name

    # Get status of dst lamp
	resp=`curl -k -s -H "$header" -X GET $huebridge/clip/v2/resource/$api_dst_light/$dst_lightid`
	dst_on=`echo $resp | jq -r .data[].on.on` #get status

    # Get name of dst light or group
    if [[ $dst == "group" ]]; then
        # actions when to turn on a group of lights
        dst_room_id=`echo $resp | jq -r '.data[] | select(.id == "'"$dst_lightid"'") | .owner.rid'` #get ID of room the group belongs to
        resp=`curl -k -s -H "$header" -X GET $huebridge/clip/v2/resource/room/$dst_room_id`
        dst_name=`echo $resp | jq -r '.data[] | select(.id=="'"$dst_room_id"'") | .metadata.name'`" (group)" #get room name
    else
        dst_name=`echo $resp | jq .data[].metadata.name` #get name of single light
    fi

	echo
	echo " Source Light $src_lightid:" 
	echo "  - on:        "$src_on
	echo "  - name:      "$src_name
	echo
	echo " Destination Light $dst_lightid:" 
	echo "  - on:        $dst_on"
	echo "  - name:      "$dst_name
    echo "  - dst:       "$dst
	echo
	
	if [[ $src_on == true ]]; then
		# Src light is shining
		if [[ $dst_on == false ]]; then 
			# Dst light is off, lets turn ON!
			echo "Light $src_lightid is turned on and reachable!"
			echo "Will activate light $dst_lightid..."
			echo
			resp=`curl -k -s -H "$header" -X PUT -d '{ "on" : { "on" : true }}' $huebridge/clip/v2/resource/$api_dst_light/$dst_lightid`
            if ! [ -f $dst_lightid.started ]; then echo 0 > $dst_lightid.started ; fi #create startfile for dst light
		else
            # Dst light is shining, reset timer to 0
            X=$(< $dst_lightid.started)
            if (( $X !=0 )); then
                echo 0 > $dst_lightid.started
            fi
        fi
	elif [[ $dst_on == true ]]; then
		# Source light is not shining and dst light is switched on
        X=$(< $dst_lightid.started)
        if (( $X < $off_delay )); then
            # Need to wait till delay time has finished
            Y=$(($X+$script_interval))
            echo $Y > $dst_lightid.started
        else
		    # Need to switch off dst light now
		    echo
		    echo "Will switch off light $dst_lightid after $off_delay secs..."
            echo
            resp=`curl -k -s -H "$header" -X PUT -d '{ "on" : { "on" : false }}' $huebridge/clip/v2/resource/$api_dst_light/$dst_lightid`
            echo 0 > $dst_lightid.started
        fi
	fi
}

if ! test -f $api_key_file; then
	# API keyfile not found -> generate API key
	curl -k -s -X POST -d '{ "devicetype" : "my_app#plukkie", "generateclientkey" : true }' $huebridge/api > $api_key_file
fi

# Fetch API key from file
if grep -q error "$api_key_file"; then
	# no valid username found
	echo "There was an error fetching username."
	echo "This is the message found in the userfile:"
	cat $api_key_file | jq
	echo "Trying to get username now..."
	curl -k -s -X POST -d '{ "devicetype" : "my app#plukkie", "generateclientkey" : true }' $huebridge/api > $api_key_file
	if grep -q error "$api_key_file"; then
		echo "Still failed to get username. Exit now."
		exit 0
	else
		user=`cat $api_key_file | jq -r .[].success.username`
	fi
else
	# Get APi username
    echo 'Get API details from file...'
	user=`cat $api_key_file | jq -r .[].success.username`
    clientkey=`cat $api_key_file | jq -r .[].success.clientkey`
    echo
	echo ' API user: ' $user
    echo ' API clientkey: ' $clientkey
    echo ' IP HUE bridge: ' $huebridge 
    echo ' Turn off delay: ' $off_delay seconds
    echo
fi

# Check lights of bathroom for bathroom closet
dst=single
src_lightid=$BK_wipper_ID
dst_lightid=$BK_lightstrip_ID
check_lights

# Check light of kitchen for kitchen closet
src_lightid=$Keuken_wipper_ID
dst_lightid=$Keuken_Kast_ID
dst=group
check_lights
