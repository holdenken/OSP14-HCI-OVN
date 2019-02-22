
# unset any previous rc file variables
unset OS_PASSWORD OS_AUTH_URL OS_USERNAME OS_TENANT_NAME OS_NO_CACHE OS_IDENTITY_API_VERSION OS_PROJECT_DOMAIN_NAME OS_USER_DOMAIN_NAME


#  Variables
# change these to match your controller and compute hostnames:
export DOMAIN_NAME=LAB
export DEMO_PROJECT=Demo
export OVERCLOUD_HOME='/home/stack/'
export OVERCLOUD_NAME=overcloud


# Script

# Create tenants within LAB Domain
source overcloudrc

# Create external network on VLAN 5

openstack network create --external --provider-network-type vlan --provider-physical-network datacentre --provider-segment 5 ext-net
openstack subnet create ext-subnet --network ext-net --dhcp --allocation-pool start=192.168.1.50,end=192.168.1.99 --dns-nameserver 192.168.1.249 --subnet-range 192.168.0.0/23

openstack network create --provider-network-type vlan --provider-physical-network provider --provider-segment 400 400net
openstack subnet create ext-subnet --network 400net --dhcp --allocation-pool start=192.168.40.100,end=192.168.40.200 --dns-nameserver 192.168.1.249 --subnet-range 192.168.40.0/24

