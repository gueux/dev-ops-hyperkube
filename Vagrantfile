# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.env.enable
  config.vm.box = "ubuntu/trusty64"
  #config.vm.box_url = "https://oss-binaries.phusionpassenger.com/vagrant/boxes/latest/ubuntu-14.04-amd64-vbox.box"
  # Or, for Ubuntu 12.04:
  #config.vm.box = "phusion-open-ubuntu-12.04-amd64"
  #config.vm.box_url = "https://oss-binaries.phusionpassenger.com/vagrant/boxes/latest/ubuntu-12.04-amd64-vbox.box"

  config.trigger.before :reload, stdout: true do
    puts "Remove 'synced_folders' file for #{@machine.name}"
    `rm .vagrant/machines/#{@machine.name}/virtualbox/synced_folders`
  end

  config.vm.synced_folder "/usr/local/bin/kubectl", "/usr/local/bin/kubectl", id: "vagrant"
  config.vm.synced_folder "./mysql-replication", "/home/vagrant/mysql-replication", id: "vagrant"

  # Kubernetes Master
  config.vm.define 'kubernetes-master' do |master|
    master.vm.hostname = 'kebernetes-master'
    master.vm.network :private_network, ip: '35.35.35.30'
    master.vm.network :forwarded_port, guest: 8080, host: 8080

    master.vm.provision :shell,
      inline: "sudo apt-get update && sudo apt-get install -y mysql-server"
    
    master.vm.provision :docker do |docker|
      # etcd
      docker.pull_images "gcr.io/google_containers/etcd:2.0.9"
      docker.run "etcd",
             image: "gcr.io/google_containers/etcd:2.0.9",
             args: "--net=host",
             cmd: "/usr/local/bin/etcd --addr=127.0.0.1:4001 --bind-addr=0.0.0.0:4001 --data-dir=/var/etcd/data",
             daemonize: true

      docker.pull_images "gcr.io/google_containers/hyperkube:v0.21.2"
      # API
      docker.run "apiserver",
             image: "gcr.io/google_containers/hyperkube:v0.21.2",
             args: "--net=host -v /var/run/docker.sock:/var/run/docker.sock",
             cmd: "/hyperkube apiserver --allow-privileged=true --insecure-bind-address=0.0.0.0 --v=2 --service-cluster-ip-range=10.0.0.0/24 --etcd-servers=http://127.0.0.1:4001 --cors_allowed_origins='http://localhost:8001'",
             daemonize: true
      # Proxy 
      docker.run "proxy", 
             image: "gcr.io/google_containers/hyperkube:v0.21.2",
             args: "--net=host --privileged",
             cmd: "/hyperkube proxy --master=http://127.0.0.1:8080 --v=2",
             daemonize: true
      # Kubelet
      docker.run "kubelet",
             image: "gcr.io/google_containers/hyperkube:v0.21.2",
             args: "--net=host --volume /var/run/docker.sock:/var/run/docker.sock",
             cmd: "/hyperkube kubelet --api_servers=http://localhost:8080 --v=2 --allow-privileged=true --address=0.0.0.0 --hostname_override=35.35.35.30 --enable-server",
             daemonize: true
      # Scheduler
      docker.run "scheduler",
             image: "gcr.io/google_containers/hyperkube:v0.21.2",
             args: "--net=host",
             cmd: "/hyperkube scheduler --master=127.0.0.1:8080 --v=2",
             daemonize: true
      # Controller
      docker.run "controller",
             image: "gcr.io/google_containers/hyperkube:v0.21.2",
             args: "--net=host",
             cmd: "/hyperkube controller-manager --master=127.0.0.1:8080 --v=2",
             daemonize: true
    end

    master.vm.provision :shell,
      inline: "kubectl -s 127.0.0.1:8080 create -f /home/vagrant/mysql-replication/mysql-master.yaml"

  end

  config.vm.define 'kubernetes-minion-1' do |minion|
    minion.vm.hostname = 'kubernetes-minion-1'
    minion.vm.network :private_network, ip: '35.35.35.31'

    master.vm.provision :shell,
      inline: "sudo apt-get update && sudo apt-get install -y mysql-server"

    minion.vm.provision :docker do |docker|
      # flannel
      docker.pull_images "yungsang/flannel"
      docker.run "flannel",
             image: "yungsang/flannel",
             args: "--net=host",
             cmd: "/go/bin/flanneld -etcd-endpoint='http://35.35.35.30:4001'",
             daemonize: true
      # Kubelet
      docker.run "kubelet",
             image: "gcr.io/google_containers/hyperkube:v0.21.2",
             args: " --net=host --volume /var/run/docker.sock:/var/run/docker.sock",
             cmd: "/hyperkube kubelet --api_servers=http://35.35.35.30:8080 --v=2 --address=0.0.0.0 --hostname_override=35.35.35.31",
             daemonize: true
      # Proxy 
      docker.run "proxy", 
             image: "gcr.io/google_containers/hyperkube:v0.21.2",
             args: "--net=host --privileged",
             cmd: "/hyperkube proxy --master=http://35.35.35.30:8080 --v=2",
             daemonize: true
    end

    master.vm.provision :shell,
      inline: "kubectl -s 127.0.0.1:8080 create -f /home/vagrant/mysql-replication/mysql-slave.yaml"

  end
end
