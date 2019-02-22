# To be run from Director upon the completion
# of your FIRST overcloud deploy.  Only run this
# script once!!!  You do not need to run this 
# every again after initial run.


#  Variables
# change these to match your controller and compute hostnames:
export CONTROL_FLAVOR=control
export COMPUTE_FLAVOR=compute
export DOMAIN_NAME=LAB
export OPENSTACK_USERS_GROUP=OpenStack-Users
export OPENSTACK_ADMIN_GROUP=OpenStack-Admins
export DEMO_PROJECT=Demo
export OVERCLOUD_HOME='/home/stack/'
export OVERCLOUD_NAME=overcloud
export AD_USER=kholden
export AD_USER_PASSWORD=Password01



# Script

# Create Domain in Keystone
source /home/stack/overcloudrc

# Allow default domain admin user to be admin in new Domain admin role
domain_id=$(openstack domain show $DOMAIN_NAME |grep id |awk '{print $4;}')
admin_id=$(openstack user list --domain default | grep admin |awk '{print $2;}')
admin_role_id=$(openstack role list |grep admin |awk '{print $2;}')
admingrp=$(openstack group show $OPENSTACK_ADMIN_GROUP --domain $DOMAIN_NAME|grep id |awk '{print $4;}'|tail -1)
usergrp=$(openstack group show $OPENSTACK_USERS_GROUP --domain $DOMAIN_NAME|grep id |awk '{print $4;}'|tail -1)

openstack role add --domain $domain_id --user $admin_id $admin_role_id
openstack role add --domain $domain_id --group $admingrp $admin_role_id


#########################################################
###   Testing Users and groups in AD     ################
#########################################################

# Example LDAP searches
# without nested
#ldapsearch -h win2k8svr.lab.lan -D 'CN=kholden,OU=People,DC=lab,DC=lan' -w 'Password01' -b dc=lab,dc=lan -E pr=10000/noprompt '(&(objectClass=organizationalPerson)(sAMAccountName=*)(memberOf=cn=OpenStack,ou=People,dc=lab,dc=lan))' |grep sAMAccountName\:

# with nested
#ldapsearch -h win2k8svr.lab.lan -D 'CN=kholden,OU=People,DC=lab,DC=lan' -w 'Password01' -b dc=lab,dc=lan -E pr=10000/noprompt '(&(objectClass=organizationalPerson)(sAMAccountName=*)(memberOf:1.2.840.113556.1.4.1941:=cn=OpenStack,ou=People,dc=lab,dc=lan))' 

# OpenStack CLI user list
#openstack user list --domain $DOMAIN_NAME

# OpenStack CLI group list
#openstack group list --domain $DOMAIN_NAME

# OpenStack CLI group list for users
openstack group list --user kholden --user-domain lab

# OpenStack CLI user list for group
openstack user list --group OpenStack-admins --domain lab

