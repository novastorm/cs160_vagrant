This is a Virtual Machine image created for the CS160 Software engineering class. VirtualBox and Vagrant makes this OS independent.

Requirements:

VirtualBox - https://www.virtualbox.org
Vagrant - http://www.vagrantup.com

$INSTALL_DIR/moocs - project web files

Directory Listing:

./VagrantFile
./assets
./manifests
./manifests/default.pp

Add CS 160 project repo
=======================
 git submodule add git@github.com:dimaj/moocs.git moocs
: This adds the repo as the moocs directory

Run the image
=============
 vagrant up
: This sets up and starts the VM

Verify the service
==================
 go to 192.168.33.10 in your web browser
: If there is an IP conflict, update the IP address in the VagantFile to an open IP address.

Accessing the VM shell
======================
 vagrant ssh

Additional vagrant commands
===========================
 vagrant halt - stop the VM
 vagrant suspend - suspend the running VM
 vagrant resume - resume a suspended VM
 vagrant destroy - halt the VM and remove the instance.

Note
====
I have tested this a couple times and it *should* work. Please direct questions to me. =AD= adland(at)4mfd(dot)com

