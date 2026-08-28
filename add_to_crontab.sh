#!/bin/bash

# NOTE
# Crontab can only scchedule at 1  inute interval at the minimum
# Therefore to run the script at lower intervals change the crontab line as desired
# example
# The constant " script_interval=20 " in script huev2.sh means run the script every 20 secs
# The crontab line shiould specify 60/20 = 3 times the huev2.sh script

if sudo crontab -l 2>/dev/null | grep -q "hue"; then
    echo "Script already in crontab :-)" 
    exit 0
else
    echo "Adding script execution into crontab..." 
    echo "* * * * * cd my_scripts/philips-hue && ./huev2.sh && sleep 20 && ./huev2.sh && sleep 20 && ./huev2.sh" >> $crontabfile
    echo "Done"
    exit 0
fi
