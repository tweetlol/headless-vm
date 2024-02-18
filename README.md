# setup a headless VM on ubuntu server to use with VNC (or ssh)

## prequisites

- fresh Ubuntu (tested on 23.10.1-desktop)
- installed VirtualBox 7.0.10:

```sh
sudo apt install VirtualBox
```

## the script

- allocated resources to the VM and basic networking settings
- internet connection shared from host

```sh
# HW PROPERTIES
MEMORY="4096"
CPUS="8"
DISK_SIZE_GB="20" #IN GB
DISK_SIZE_MB=$((DISK_SIZE_GB * 1000))
DISK_FORMAT="VDI"

# NETWORK CONFIGURATION
NETWORK_ADAPTER="nat"
PORT=10001
```

- `$ISO_LINK` determines .iso image to be downloaded and installed, should you choose to `y`
- script proceeds to ask for a desired machine name, and if you want to download an imagefile from `$ISO_LINK`

```sh
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
```

- check for `$ISO_FILE` in current directory, if found proceed to setup and start the VM

```sh
# CHECK FOR .ISO
if [ ! -f ./$ISO_FILE ]; then
        echo "$ISO_FILE not found, quitting..."
else
        echo "$ISO_FILE found, creating vm $MACHINENAME..."

# CREATE VM
        VBoxManage createvm --name $MACHINENAME --ostype "Ubuntu_64" --register --basefolder `pwd`

# SET RAM AND NETWORK ADAPTER (CHANGE NETWORK ADAPTER FOR SSH ACCESS LATER - bridge?)
        VBoxManage modifyvm $MACHINENAME --memory $MEMORY --cpus $CPUS
        VBoxManage modifyvm $MACHINENAME --nic1 $NETWORK_ADAPTER

# CREATE HDD AND CONNECT UBUNTU.ISO
        VBoxManage createhd --filename `pwd`/$MACHINENAME/$MACHINENAME-disk.vdi --size $DISK_SIZE_MB --format $DISK_FORMAT
        VBoxManage storagectl $MACHINENAME --name "SATA Controller" --add sata
        VBoxManage storageattach $MACHINENAME --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium  `pwd`/$MACHINENAME/$MACHINENAME-disk.vdi
        VBoxManage storagectl $MACHINENAME --name "IDE Controller" --add ide
        VBoxManage storageattach $MACHINENAME --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium `pwd`/$ISO_FILE
        VBoxManage modifyvm $MACHINENAME --boot1 dvd --boot2 disk --boot3 none --boot4 none

# ENABLE REMOTE DESKTOP PROTOCOL AT PORT 10001
        VBoxManage modifyvm $MACHINENAME --vrde on
        VBoxManage modifyvm $MACHINENAME --vrdemulticon on --vrdeport $PORT

# SETUP VNC PASSWORD
        echo "vnc password for $MACHINENAME?:"
        read PASSWORD
        VBoxManage modifyvm $MACHINENAME --vrdeproperty VNCPassword=$PASSWORD

# SETUP DONE
        echo "setup done, start $MACHINENAME with start-vm.sh"
fi
```

## connecting with VNC

- connect to VM remotely using TigerVNC Viewer to `localhost:$PORT` (default `PORT=10001`)

## ssh access (optional)

- `NETWORK_ADAPTER="nat"` is not optimal for ssh
- set another network adapter to "bridged" mode

```sh
VBoxManage modifyvm $MACHINENAME --nic2 bridged
```

- bridge to your host adapter (ex. enp1s0f0, `ip a` on host machine to find out)

```sh
VBoxManage modifyvm $MACHINENAME --bridgeadapter2 $HOSTADAPTER
```

- reboot, the machine should now be accessible across your local network behind it's own IP address
