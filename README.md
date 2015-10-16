# docker-hyperkube
Start up the kubernetes hyperkube in Vagrant

To start master with 2 minions:
```
vagrant up
```

To start [fabric8!](https://www.github.com/fabric8io/fabric8) onto the kubernetes cluster:
```
kubectl create -f ./kubectl-scenarios/fabric8/fabric8-ui.json
```
