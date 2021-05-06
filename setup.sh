#!/bin/bash

set -eo pipefail

dir=$(dirname $0)

kubectl create namespace kubernetes-dashboard \
  --dry-run=client -o yaml | kubectl apply -f -

if [ -d $dir/ssl ]; then

  certs=("dashboard")
  for c in ${certs[@]}; do
    kubectl create secret tls "$c-tls" -n kubernetes-dashboard \
      --cert=$dir/ssl/_wildcard.local.dev.pem \
      --key=$dir/ssl/_wildcard.local.dev-key.pem \
      --dry-run=client -o yaml | kubectl apply -f - 
  done 
fi 

helm upgrade kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
  -f ${dir}/kubernetes-dashboard-values.yaml -n kubernetes-dashboard\
  --install --wait --timeout 15m
      
kubectl apply -f ${dir}/kubernetes-dashboard-crb.yaml -n kubernetes-dashboard \
  --dry-run=client -o yaml | kubectl apply -f -      

kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=kubernetes-dashboard  \
   -n kubernetes-dashboard

kubectl -n kubernetes-dashboard describe secret  \
  $(kubectl -n kubernetes-dashboard get secret | grep kubernetes-dashboard-token | awk '{print $1}')      

echo ""
echo "token for kubernetes-dashboard login"

echo "Application URL https://dashboard.local.dev"