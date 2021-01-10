# kubernetes-dashboard
A setup enviornment using [kind](https://kind.sigs.k8s.io) and leveraging the standard helm chart

Use ```setup-cluster.sh``` to create a local development cluster. The cluster features a nginx based ingress controller.
Add kubernetes-dashboard helm repo with ```helm repo add	https://kubernetes.github.io/dashboard/ ``` and execute ```./install-kubernetes-dashboard.sh```