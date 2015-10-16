# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"
NUMBER_OF_MINIONS=2

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

  config.vm.synced_folder "../dev-ops-hyperkube", "/opt/dev_ops_hyperkube", id: "vagrant"

  # Kubernetes Master
  config.vm.define 'kubernetes-master' do |master|
    master.vm.hostname = 'kebernetes-master'
    master.vm.network :private_network, ip: '35.35.35.30'
    
    master.vm.network :forwarded_port, guest: 8080, host: 8080
    master.vm.network :forwarded_port, guest: 3001, host: 3001

    master.vm.provision :docker do |docker|

      # Pull images firstly
      docker.pull_images "gcr.io/google_containers/etcd:2.0.9"
      docker.pull_images "gcr.io/google_containers/hyperkube:v0.21.2"
      docker.pull_images "gcr.io/google_containers/kube-ui:v1.1"
      
      # Run containers with: 
      # etcd
      docker.run "etcd",
             image: "gcr.io/google_containers/etcd:2.0.9",
             args: "--net=host",
             cmd: "/usr/local/bin/etcd --addr=127.0.0.1:4001 --bind-addr=0.0.0.0:4001 --data-dir=/var/etcd/data",
             daemonize: true      
      # API
      docker.run "apiserver",
             image: "gcr.io/google_containers/hyperkube:v0.21.2",
             args: "--net=host -v /var/run/docker.sock:/var/run/docker.sock ",
             cmd: "/hyperkube apiserver --allow-privileged=true --insecure-bind-address=0.0.0.0 --v=2 --service-cluster-ip-range=10.100.0.0/16 --etcd-servers=http://127.0.0.1:4001 --cors_allowed_origins=.*",
             daemonize: true
      # Proxy 
      docker.run "proxy", 
             image: "gcr.io/google_containers/hyperkube:v0.21.2",
             args: "--net=host --privileged",
             cmd: "/hyperkube proxy --master=http://127.0.0.1:8080 --v=2",
             daemonize: true
      # Scheduler
      docker.run "scheduler",
             image: "gcr.io/google_containers/hyperkube:v0.21.2",
             args: "--net=host",
             cmd: "/hyperkube scheduler --master=127.0.0.1:8080 --v=2",
             daemonize: true
      # Replication Controller
      docker.run "controller",
             image: "gcr.io/google_containers/hyperkube:v0.21.2",
             args: "--net=host",
             cmd: "/hyperkube controller-manager --master=127.0.0.1:8080 --v=2",
             daemonize: true
      # Kubernetes-UI
      docker.run "kube-ui",
             image: "gcr.io/google_containers/kube-ui:v1.1",
             daemonize: true
    end
    
    # Install kubectl & etcdctl & provide flannel network keys
    master.vm.provision :shell,
      inline: "cd /opt/dev_ops_hyperkube && sudo make kubectl && sudo make etcdctl && make etcd-network"
    # Install flanneld  
    master.vm.provision :shell, 
        privileged: true,
        inline: "cp /opt/dev_ops_hyperkube/etc/default.flanneld /etc/default/flanneld && \
                 cp /opt/dev_ops_hyperkube/etc/init.flanneld.conf /etc/init/flanneld.conf && \
                 cp /opt/dev_ops_hyperkube/bin/flanneld /usr/local/sbin/flanneld && service flanneld start"
  end

  # Kubernetes Minions
  NUMBER_OF_MINIONS.times do |i|

    minion_name = "kubernetes-minion-#{i+1}"
    minion_ip = "35.35.35.3#{i+1}"

    config.vm.define "#{minion_name}" do |minion|

      minion.vm.hostname = "#{minion_name}"
      minion.vm.network :private_network, ip: "#{minion_ip}"

      minion.vm.provision :shell, 
        privileged: true,
        inline: "cp /opt/dev_ops_hyperkube/etc/default.flanneld /etc/default/flanneld && \
                 cp /opt/dev_ops_hyperkube/etc/init.flanneld.conf /etc/init/flanneld.conf && \
                 cp /opt/dev_ops_hyperkube/bin/flanneld /usr/local/sbin/flanneld && start flanneld"

      minion.vm.provision :shell, 
        privileged: true,
        inline: "cp /opt/dev_ops_hyperkube/etc/default.docker /etc/default/docker"

      minion.vm.provision :docker do |docker|
        
        # Pull images
        docker.pull_images "gcr.io/google_containers/hyperkube:v0.21.2"

        # Kubelet
        docker.run "kubelet",
               image: "gcr.io/google_containers/hyperkube:v0.21.2",
               args: " --net=host --volume /var/run/docker.sock:/var/run/docker.sock",
               cmd: "/hyperkube kubelet --api_servers=http://35.35.35.30:8080 --v=2 --address=0.0.0.0",
               daemonize: true
        # Proxy 
        docker.run "proxy", 
               image: "gcr.io/google_containers/hyperkube:v0.21.2",
               args: "--net=host --privileged",
               cmd: "/hyperkube proxy --master=http://35.35.35.30:8080 --v=2",
               daemonize: true
      end
    end
  end

end
