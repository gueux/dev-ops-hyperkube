# Makefile for the R&R Music kubernetes cluster
# MAINTAINER: Ihor Savchenko <redden.tears@gmail.com>
# If you update this image please check the tag value before pushing.

.PHONY: vagrant-cluster master minion kube-ui

vagrant-cluster: Vagrantfile
	vagrant up

kubectl: 
	wget -O /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.0.1/bin/linux/amd64/kubectl
	chmod +x /usr/local/bin/kubectl

master: kubectl kubernetes-master.yml kubernetes-minion.yml
	docker-compose -f ./cluster-compose/kubernetes-master.yml

minion: kubernetes-minion.yml
	docker-compose -f ./cluster-compose/kubernetes-minion.yml
    