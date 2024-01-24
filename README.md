# setup a headless VM on ubuntu server to use with Remmina VNC (VirtualBox)

___

## prequisites

- fresh Ubuntu (tested on 23.10.1-desktop)
- installed VirtualBox 7.0.10:
`sudo apt install VirtualBox`

___

## the script

- allocated resources to the VM and basic networking settings
- internet connection shared from host

```
#################################################

#       VIRTUALBOX VM PARAMETERS

#################################################

# HW PROPERTIES
MEMORY="1024"
CPUS="2"
DISK_SIZE_GB="15" #IN GB
DISK_SIZE_MB=$((DISK_SIZE_GB * 1000))
DISK_FORMAT="VDI"

# NETWORK CONFIGURATION
NETWORK_ADAPTER="nat"
PORT=10001

# .ISO IMAGE LINK
ISO_FILE="ubuntu-22.04.3-live-server-amd64.iso"
ISO_LINK="https://releases.ubuntu.com/22.04.3/$ISO_FILE"
```

- `$ISO_LINK` determines .iso image to be downloaded and installed, should you choose to `y`
- script proceeds to ask for a desired machine name, and if you want to download an imagefile from `$ISO_LINK`

```
#################################################

#       RUNTIME

#################################################

# UI
echo "virtual machine name?:"
read MACHINENAME
echo "creating $MACHINENAME" 
echo "download $ISO_LINK"
echo "as .iso image file [y/n]?:"
read DOWNLOAD

if [ "$DOWNLOAD" = "y" ]; then
        echo "downloading $ISO_LINK"
        wget -O $ISO_FILE --show-progress $ISO_LINK
fi

# CHECK FOR .ISO
if [ ! -f ./ubuntu.iso ]; then
        echo "$ISO_FILE not found, quitting..."
else
        echo "$ISO_FILE found, creating vm $MACHINENAME..."
```

- check for `$ISO_FILE` in current directory, if found proceed to setup and start the VM

```
# CREATE VM
        VBoxManage createvm --name $MACHINENAME --ostype "Ubuntu_64" --register --basefolder `pwd`

# SET RAM AND NETWORK ADAPTER (CHANGE NETWORK ADAPTER FOR SSH ACCESS LATER - bridge?)
        VBoxManage modifyvm $MACHINENAME --memory $MEMORY --cpus $CPUS
        VBoxManage modifyvm $MACHINENAME --nic1 $NETWORK_ADAPTER

# CREATE HDD AND CONNECT UBUNTU.ISO
        VBoxManage createhd --filename `pwd`/$MACHINENAME/$MACHINENAME-disk.vdi --size $DISK_SIZE_MB --format $DISK_FORMAT
        VBoxManage storagectl $MACHINENAME --name "SATA Controller" --add sata
        VBoxManage storageattach $MACHINENAME --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium `pwd`/$MACHINENAME/$MACHINENAME-disk.vdi
        VBoxManage storagectl $MACHINENAME --name "IDE Controller" --add ide
        VBoxManage storageattach $MACHINENAME --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium `pwd`/ubuntu.iso
        VBoxManage modifyvm $MACHINENAME --boot1 dvd --boot2 disk --boot3 none --boot4 none

# ENABLE REMOTE DESKTOP PROTOCOL AT PORT 10001
        VBoxManage modifyvm $MACHINENAME --vrde on
        VBoxManage modifyvm $MACHINENAME --vrdemulticon on --vrdeport $PORT

# SETUP VNC PASSWORD
        echo "vnc password for $MACHINENAME?:"
        read PASSWORD
        VBoxManage modifyvm $MACHINENAME --vrdeproperty VNCPassword=$PASSWORD

# START THE THING
        echo "setup done, starting $MACHINENAME..."
        VBoxHeadless --startvm $MACHINENAME &
        echo "success: virtual machine $MACHINENAME running! vrde port $PORT"
fi
```

- connect to VM remotely using Remmina VNC to `localhost:$PORT` (default `PORT=10001`)

___

## ssh access (optional)

- `NETWORK_ADAPTER="nat"` is not optimal for ssh
- `VBoxManage modifyvm $MACHINENAME --nic1 bridged` set network adapter to "bridged"
- `VBoxManage modifyvm $MACHINENAME --bridgeadapter1 $HOSTADAPTER` bridge to your host adapter (ex. enp1s0f0, `ip a` to find out)
- reboot, the machine should now be accessible across your local network behind it's own IP address

___
