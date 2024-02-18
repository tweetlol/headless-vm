#!/bin/bash

#VIRTUALBOX, VM
#START THE THING
echo "name a virtual machine to start:"
read MACHINENAME
echo "starting $MACHINENAME..."
VBoxHeadless --startvm $MACHINENAME &

