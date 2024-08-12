#!/bin/bash

############################################################
## This script activates lights on the Philips Hue bridge ##
## Bridge API version: v2                                 ##
############################################################

# BEGIN CONSTANTS
#huebridge='https://10.100.102.138'
huebridge='https://192.168.0.103'
api_user_file='hue_api_user.txt'

# END CONSTANTS

# Badkamer spot src = 1
# Badkamer lightstrip kast = 2
function check_lights { src_lightid=1; dst_lightid=1;
	# Function that gets status of src lamp
	# Both 'on' and 'reachability' need to be true to activate dst lamp
	resp=`curl -k -s -X GET $huebridge/api/$user/lights/$src_lightid | jq -r .state`
	src_on=`echo $resp | jq -r .on`
	src_reachable=`echo $resp | jq -r .reachable`
	resp=`curl -k -s -X GET $huebridge/api/$user/lights/$dst_lightid | jq -r .state`
	dst_on=`echo $resp | jq -r .on`
	dst_reachable=`echo $resp | jq -r .reachable`
	echo
	echo " Light $src_lightid:" 
	echo "  - on:        $src_on"
	echo "  - reachable: $src_reachable"
	echo
	echo " Light $dst_lightid:" 
	echo "  - on:        $dst_on"
	echo "  - reachable: $dst_reachable"
	echo
	
	if [[ $src_on == true && $src_reachable == true ]]; then
		# Src light is shining
		if [[ $dst_on == false ]]; then 
			# Switch on dst light
			echo "Light $src_lightid is turned on and reachable!"
			echo "Will activate light $dst_lightid..."
			echo
			resp=`curl -k -s -X PUT -d '{ "on" : true }' $huebridge/api/$user/lights/$dst_lightid/state`
		fi
	elif [[ $dst_on == true ]]; then
		# Source light is not shining and dst light is switched on
		# Need to switch off dst light now
		echo
		echo "Will switch off light $dst_lightid..."
        echo
        resp=`curl -k -s -X PUT -d '{ "on" : false }' $huebridge/api/$user/lights/$dst_lightid/state`
	fi
}


if ! test -f $api_user_file; then
	# userfile not found, create API user
	curl -k -s -X POST -d '{"devicetype":"my_app#plukkie","generateclientkey":true}' $huebridge/api > $api_user_file
fi

# Fetch username from file
if grep -q error "$api_user_file"; then
	# no valid username found
	echo "There was an error fetching username."
	echo "This is the message found in the userfile:"
	cat $api_user_file | jq
	echo "Trying to get username now..."
	curl -k -s -X POST -d '{"devicetype":"my app#plukkie", "generateclientkey":true}' $huebridge/api > $api_user_file
	if grep -q error "$api_user_file"; then
		echo "Still failed to get username. Exit now."
		exit 0
	else
		user=`cat $api_user_file | jq -r .[].success.username`
	fi
else
	# Get APi username
	user=`cat $api_user_file | jq -r .[].success.username`
fi

#check_lights

