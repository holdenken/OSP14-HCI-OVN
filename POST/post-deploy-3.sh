#!/bin/bash
#########################################################
#  create Demo tenant withing AD domain
#########################################################

# unset any previous rc file variables
unset OS_PASSWORD OS_AUTH_URL OS_USERNAME OS_TENANT_NAME OS_NO_CACHE OS_IDENTITY_API_VERSION OS_PROJECT_DOMAIN_NAME OS_USER_DOMAIN_NAME
for key in $( set | awk '{FS="="}  /^OS_/ {print $1}' ); do unset $key ; done


#  Variables
# change these to match your controller and compute hostnames:
export DOMAIN_NAME=LAB
export OPENSTACK_USERS_GROUP=OpenStack-Users
export OPENSTACK_ADMIN_GROUP=OpenStack-Admins
export DEMO_PROJECT=Demo
export OVERCLOUD_HOME='/home/stack/'
export OVERCLOUD_NAME=overcloud
export AD_USER=kholden
export AD_USER_PASSWORD=Password01

# Script

# Create tenants within LAB Domain
cd $OVERCLOUD_HOME
source overcloudrc
openstack user list --domain $DOMAIN_NAME
domain_id=$(openstack domain show $DOMAIN_NAME |grep id |awk '{print $4;}')
admingrp=$(openstack group show $OPENSTACK_ADMIN_GROUP --domain $DOMAIN_NAME|grep id |awk '{print $4;}'|tail -1)
usergrp=$(openstack group show $OPENSTACK_USERS_GROUP --domain $DOMAIN_NAME|grep id |awk '{print $4;}'|tail -1)
admin_role_id=$(openstack role list |grep admin |awk '{print $2;}')
member_role_id=$(openstack role list |grep member |awk '{print $2;}')

# Create Project / Tenant within LDAP-based Domain
openstack project create $DEMO_PROJECT --domain $DOMAIN_NAME

# Gather project IDs
project_Demo=$(openstack project list --domain $DOMAIN_NAME|grep $DEMO_PROJECT  |awk '{print $2;}')

# Configure Admin and _member_ privs
openstack role add --project $project_Demo --group $admingrp $admin_role_id
openstack role add --project $project_Demo --group $usergrp $member_role_id

# create AD-User-based file
cp  overcloudrc overcloudrc_$OVERCLOUD_NAME_$AD_USER
sed -i -e 's/'USERNAME\=admin/USERNAME\="$AD_USER"'/g' overcloudrc_$AD_USER
sed -i -e 's/'Default/"$DOMAIN_NAME"'/g' overcloudrc_$AD_USER
sed -i -e 's/'OS\_PROJECT\_NAME\=admin/OS\_PROJECT\_NAME\="$DEMO_PROJECT"'/g' overcloudrc_$AD_USER
sed -i -e 's/'export\ OS\_PASSWORD\=.*/export\ OS\_PASSWORD\="$AD_USER_PASSWORD"'/g' overcloudrc_$AD_USER

unset OS_PASSWORD OS_AUTH_URL OS_USERNAME OS_TENANT_NAME OS_NO_CACHE OS_IDENTITY_API_VERSION OS_PROJECT_DOMAIN_NAME OS_USER_DOMAIN_NAME
for key in $( set | awk '{FS="="}  /^OS_/ {print $1}' ); do unset $key ; done
source overcloudrc_$AD_USER

export DOMAIN_NAME=LAB
export OPENSTACK_USERS_GROUP=OpenStack-Users
export OPENSTACK_ADMIN_GROUP=OpenStack-Admins
export DEMO_PROJECT=Demo
export OVERCLOUD_HOME='/home/stack/'
export OVERCLOUD_NAME=overcloud
export AD_USER=kholden
export AD_USER_PASSWORD=Password01

# Create tenant networking
openstack network create $DEMO_PROJECT-net --project-domain $DOMAIN_NAME --project $DEMO_PROJECT
openstack subnet create --project $DEMO_PROJECT --subnet-range 192.168.101.0/24 --allocation-pool start=192.168.101.100,end=192.168.101.150 --dhcp --ip-version 4 --network $DEMO_PROJECT-net --dns-nameserver 192.168.1.249 $DEMO_PROJECT-subnet
openstack router create --project $DEMO_PROJECT $DEMO_PROJECT-router --project-domain $DOMAIN_NAME --project $DEMO_PROJECT
openstack router add subnet $DEMO_PROJECT-router $DEMO_PROJECT-subnet 
openstack router set  --external-gateway ext-net $DEMO_PROJECT-router
# No openstack unified cli for adding gateway that I am aware of 
# neutron router-gateway-set $DEMO_PROJECT-router ext-net


# add your ssh keypair to nova
openstack keypair create --public-key /home/stack/.ssh/id_rsa.pub stack-director-keypair

# create a glance image for deployment
#sudo yum -y install rhel-guest-image-7.noarch
#openstack image create --public --container-format bare --disk-format qcow2 --file /usr/share/rhel-guest-image-7/rhel-guest-image-7.2-20160302.0.x86_64.qcow2 rhel-7.2
#cp /usr/share/rhel-guest-image-7/rhel-guest-image-7.2-20160302.0.x86_64.qcow2 ~/images/rhel-7.2.qcow2
#virt-customize -a ~/images/rhel-7.2.qcow2 --copy-in /etc/yum.repos.d/local.repo:/etc/yum.repos.d/
#virt-customize -a ~/images/rhel-7.2.qcow2 --run-command 'yum -y install qemu-guest-agent'
#virt-customize -a ~/images/rhel-7.2.qcow2 --root-password password:Redhat01
openstack image create --public --container-format bare --disk-format qcow2 --property hw_disk_bus=scsi --property hw_scsi_model=virtio-scsi --property hw_qemu_guest_agent=yes --file ~/images/rhel75.qcow2 rhel75



# create flavors
# create some instances
openstack flavor create --id auto --ram 1024 --disk 10 --vcpu 1 small
openstack flavor create --id auto --ram 512 --disk 1 --vcpu 1 tiny
openstack flavor create --id auto --ram 2048 --disk 20 --vcpu 1 medium
openstack flavor create --id auto --ram 4096 --disk 40 --vcpu 2 large

# allow ssh, http and icmp to the demo tenant network
demo_project=$(openstack project list| grep $DEMO_PROJECT | awk '{print $2;}')
demo_security_group=$(openstack security group list | grep $demo_project| awk '{print $2;}')
openstack security group rule create --protocol tcp --dst-port 22:22 $demo_security_group
openstack security group rule create --protocol tcp --dst-port 80:80 $demo_security_group
openstack security group rule create --protocol tcp --dst-port 443:443 $demo_security_group
openstack security group rule create --protocol icmp  $demo_security_group


# create some instances
demo_net=$(openstack network list | grep -i $DEMO_PROJECT | awk '{print $2;}')
openstack server create --flavor small --image rhel75 --security-group $demo_security_group --key-name stack-director-keypair --nic net-id=$demo_net test1

sleep 20

# create a floating private IP
openstack floating ip create ext-net
floating_ip=$(openstack floating ip list |grep 192.168.1. |awk '{print $4;}')
openstack server add floating ip test1 $floating_ip
ping -c1 $floating_ip
