
openstack loadbalancer create --name loadbalancer1 --vip-subnet-id admin-subnet
sleep 120
openstack loadbalancer listener create  --name listener1 --protocol http --protocol-port 80 --enable loadbalancer1
openstack loadbalancer pool create --name pool1 --protocol http --listener listener1 --enable --lb-algorithm ROUND_ROBIN
openstack loadbalancer healthmonitor create --name healthmonitor1 --type ping --enable --delay 3 --timeout 3 --max-retries 3 pool1
