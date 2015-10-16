# Makefile for the R&R Music kubernetes cluster
# MAINTAINER: Ihor Savchenko <redden.tears@gmail.com>
# If you update this image please check the tag value before pushing.

.PHONY: vagrant-cluster kubectl etcdctl etcd-network master minion kube-ui

vagrant-cluster: Vagrantfile
	vagrant up

kubectl: 
	wget -O /usr/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.0.1/bin/linux/amd64/kubectl
	chmod +x /usr/bin/kubectl

etcdctl: 
	wget -O /tmp/etcd-v2.2.0-linux-amd64.tar.gz https://github.com/coreos/etcd/releases/download/v2.2.0/etcd-v2.2.0-linux-amd64.tar.gz
	tar -xzvf /tmp/etcd-v2.2.0-linux-amd64.tar.gz -C /opt/
	mv /opt/etcd-v2.2.0-linux-amd64/etcdctl /usr/bin/etcdctl
	chmod +x /usr/bin/etcdctl

etcd-network: etcdctl
	etcdctl setdir /registry/network/ 
	etcdctl set /registry/network/config '{ "Network": "10.10.0.0/16"} '

master: kubectl kubernetes-master.yml
	docker-compose -f ./cluster-compose/kubernetes-master.yml

minion: kubernetes-minion.yml
	docker-compose -f ./cluster-compose/kubernetes-minion.yml


    
