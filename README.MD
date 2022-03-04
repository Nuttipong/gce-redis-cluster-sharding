## Configure gcloud
```
gcloud init
gcloud auth list
gcloud auth activate-service-account --key-file=tdg-ct-carbontrace-nonprod-brx-8fc68b01960d.json
gcloud auth login --cred-file=credential.json
gcloud auth revoke t12-automation@tdg-ct-carbontrace-nonprod-brx.iam.gserviceaccount.com
gcloud auth print-access-token
gcloud config list
gcloud config set project tdg-ct-carbontrace-nonprod-brx
```
[gcloud cheat sheet](https://cloud.google.com/sdk/docs/cheatsheet)

## Create VM instance
```
gcloud compute zones list | grep asia-southeast1
gcloud compute regions list | grep asia
gcloud config set compute/zone asia-southeast1-a
gcloud compute images list --filter ubuntu-os-cloud
# os > https://cloud.google.com/compute/docs/images/os-details#ubuntu_pro

gcloud compute instances create "node1" \
--machine-type "n1-standard-1" \
--image-family "ubuntu-2004-lts" \
--image-project "ubuntu-os-cloud" \
--zone "asia-southeast1-a" \
--tags "redis-tag" \
--subnet "default"

gcloud beta redis instances create 4771612740927316446 --enable-auth --region=asia-southeast1 --zone=asia-southeast1-a --redis-version=5.0.7
gcloud beta redis instances update 4771612740927316446 --enable-auth --region=asia-southeast1




gcloud compute instances create "node2" \
--machine-type "n1-standard-1" \
--image-family "debian-9" \
--image-project "debian-cloud" \
--zone "asia-southeast1-b" \
--tags "redis-tag" \
--subnet "default"
gcloud compute instances create "node3" \
--machine-type "n1-standard-1" \
--image-family "debian-9" \
--image-project "debian-cloud" \
--zone "asia-southeast1-c" \
--tags "redis-tag" \
--subnet "default"

gcloud compute instances list
gcloud compute instances delete "node1"
```
[gcloud compute](https://cloud.google.com/sdk/gcloud/reference/compute/instances/create)

## SSH inside VM and install simple web server
```
ping node1
ssh node1
sudo apt-get install nginx-light -y
vi /var/www/html/index.nginx-debian.html
curl http://localhost
exit
```

## Create Firewall rules
```
gcloud compute firewall-rules create redis-firewall --target-tags redis-tag --allow tcp:80,tcp:7000,tcp:7001
gcloud compute firewall-rules delete redis-firewall
gcloud compute firewall-rules update redis-firewall --allow tcp:80,tcp:7000,tcp:7001,tcp:17000,tcp:17001
```

## How to setup Redis
```
sudo apt-get --purge remove redis-server
sudo rm -rf /etc/redis/dump.rdb

-------------------------------------------------------------------------
sudo apt-get update
sudo apt-get -y install redis-server
ps -f -u redis
sudo systemctl disable redis-server.service
sudo ufw allow 7000
sudo ufw allow 7001
sudo ufw allow 17000
sudo ufw allow 17001

sudo systemctl disable /etc/systemd/system/redis_7000.service
sudo systemctl disable /etc/systemd/system/redis_7001.service

# upload all redis.config and redis.service

sudo chmod +x rc.local
sudo cp rc.local /etc/rc.local

# add vm.overcommit_memory=1 at the end of the file
sudo vi /etc/sysctl.conf


# dir
sudo mkdir /etc/redis/cluster
# dir to store redis.conf
sudo mkdir /etc/redis/cluster/7000
sudo mkdir /etc/redis/cluster/7001
# redis persistence data location
sudo mkdir /var/lib/redis/7000
sudo mkdir /var/lib/redis/7001

sudo cp redis_7000.conf /etc/redis/cluster/7000/
sudo cp redis_7001.conf /etc/redis/cluster/7001/

sudo chown redis:redis -R /var/lib/redis
sudo chmod 770 -R /var/lib/redis
sudo chown redis:redis -R /etc/redis

sudo ls -l /etc/systemd/system/
sudo cp redis_7000.service /etc/systemd/system/
sudo cp redis_7001.service /etc/systemd/system/

#Tell systemd to start the two services redis_7000.service and redis_7000.#service automatically at boot by running the following commands:
sudo systemctl enable /etc/systemd/system/redis_7000.service
sudo systemctl enable /etc/systemd/system/redis_7001.service

sudo reboot
sudo tail -n 100 /var/log/redis/redis_7000.log
sudo tail -n 100 /var/log/redis/redis_7001.log
sudo systemctl status redis_7000.service
sudo systemctl status redis_7001.service
-------------------------------------------------------------------------


sudo systemctl status redis-server.service
sudo systemctl disable redis-server.service
sudo systemctl enable redis-server.service
sudo systemctl start redis-server.service
sudo systemctl stop /etc/systemd/system/redis_7000.service
sudo systemctl stop /etc/systemd/system/redis_7001.service

sudo apt-get -y install telnet
sudo tail 100 /var/log/redis/redis-server.log
```

## Creating the Redis Cluster
node1: 34.87.147.4
node2: 35.186.149.3
node3: 35.247.163.85
```
#ssh to any servers
redis-cli -a a-very-complex-password-here --cluster create \
34.87.147.4:7000 \
35.186.149.3:7000 \
35.247.163.85:7000 \
34.87.147.4:7001 \
35.186.149.3:7001 \
35.247.163.85:7001 \
--cluster-replicas 1
```
## After creating the cluster there are 16384 hash slots, divided by the 3 servers:
- node1 contains hash slots from 0 to 5500
- node2 contains hash slots from 5501 to 11000
- node3 contains hash slots from 11001 to 16383

## Checking the status of the Redis Cluster
```
redis-cli -c -h 34.87.147.4 -p 7000 -a a-very-complex-password-here
34.87.147.4:7000> CLUSTER NODES
```

## SET and GET operations to test
```
redis-cli -c -h 34.87.147.4 -p 7000 -a a-very-complex-password-here
34.87.147.4:7000> set a 1
34.87.147.4:7000> set b 2
34.87.147.4:7000> set c 3
34.87.147.4:7000> set d 4
34.87.147.4:7000> get a
34.87.147.4:7000> get b
34.87.147.4:7000> get c
34.87.147.4:7000> get d
```

## Test the failover behavior of a Redis Cluster
1. Simulating Master A unreachable
Given the master node1 unreachable
When executing script
```
redis-cli -c -h 35.247.163.85 -p 7000 -a a-very-complex-password-here DEBUG sleep 40
redis-cli -c -h 35.247.163.85 -p 7000 -a a-very-complex-password-here debug segfault
#noninteractive mode
redis-cli -a a-very-complex-password-here -h 34.87.147.4 -p 7000 get "a"
redis-cli -a a-very-complex-password-here -h 34.87.147.4 -p 7000 debug segfault
```
Then cluster will promote slave node1 as master
And cluster still 

2. Simulating node1 unavailable
```

```


## Replication and Sentinel
1. Download (redis.conf)[https://redis.io/topics/config] template
2. Alter some property which is required for the Master
```
protected-mode no
port 6379

#authen
masterauth a-very-complex-password-here
requirepass a-very-complex-password-here

#persistence
dir "/data"
dbfilename "dump.rdb"
appendonly yes
appendfilename "appendonly.aof"
```
3. Alter some property which is required for the Replica
```
slaveof 34.126.69.120 6379
```

## How to run Redis replication with Docker
```
#network
docker network create redis

#master1
docker run -d --rm --name master1 `
    --net redis `
    -v ${PWD}/master1:/etc/redis/ `
    redis:6.0-alpine redis-server /etc/redis/redis.conf

#master2
docker run -d --rm --name master2 `
    --net redis `
    -v ${PWD}/master2:/etc/redis/ `
    redis:6.0-alpine redis-server /etc/redis/redis.conf

#master3
docker run -d --rm --name master3 `
    --net redis `
    -v ${PWD}/master3:/etc/redis/ `
    redis:6.0-alpine redis-server /etc/redis/redis.conf
```

## How to execute Redis
```
ps aux | grep [r]edis
redis-cli
auth "a-very-complex-password-here"
keys *
```

## How to run app for testing
```
cd app
docker build .

docker run --rm -it \
 -e REDIS_HOST=34.126.69.120 \
 -e REDIS_PORT=6379 \
 -e REDIS_PASSWORD="a-very-complex-password-here" \
 -p 5000:80 \
 redis-app:v1
```
Refs:
- https://lightrun.com/dev-tools/using-the-redis-command-line/
- https://github.com/marcel-dempers/docker-development-youtube-series/tree/master/storage/redis/clustering
- https://www.youtube.com/watch?app=desktop&v=GEg7s3i6Jak
- https://medium.com/@pubuduboteju95/deep-dive-into-redis-clustering-1d71484578a9
- *** https://blog.opstree.com/2019/10/22/redis-cluster-architecture-replication-sharding-and-failover/
- *** https://blog.opstree.com/2019/10/29/redis-cluster-setup-sharding-and-failover-testing/
- https://mohewedy.medium.com/redis-cluster-configurations-by-example-5480a178e884
- https://redis.io/commands/failover