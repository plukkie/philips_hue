#!/bin/bash

if sudo crontab -l 2>/dev/null | grep -q "hue"; then
    echo "Script already in crontab :-)" 
    exit 0
else
    echo "Adding script execution into crontab..." 
    echo "* * * * * cd my_scripts/philips-hue && ./huev2.sh" >> $crontabfile
    echo "Done"
    exit 0
fi
