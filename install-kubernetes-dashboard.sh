#!/bin/bash

set -eo pipefail

dir=$(dirname $0)

external_domain=local

if [[ ! -f ${dir}/ssl/wildcard.${external_domain}.crt ]]; then
  mkdir -p ${dir}/ssl
  openssl req -nodes -newkey rsa:2048 -new -sha256 \
    -keyout ${dir}/ssl/wildcard.${external_domain}.key \
    -out ${dir}/ssl/wildcard.${external_domain}.csr \
    -subj "/C=/O=kind/OU=local/CN=*.${external_domain}"
  openssl x509 -req -days 365 -in ${dir}/ssl/wildcard.${external_domain}.csr \
    -signkey ${dir}/ssl/wildcard.${external_domain}.key \
    -out ${dir}/ssl/wildcard.${external_domain}.crt  
fi    

kubectl create namespace kubernetes-dashboard \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret tls kubernetes-dashboard-tls --namespace kubernetes-dashboard \
  --cert=${dir}/ssl/wildcard.${external_domain}.crt --key=${dir}/ssl/wildcard.${external_domain}.key \
  --dry-run=client -o yaml | kubectl apply -f -

helm upgrade kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
  -f ${dir}/kubernetes-dashboard/kubernetes-dashboard-values.yaml -n kubernetes-dashboard\
  --install --wait --timeout 15m
      
kubectl apply -f ${dir}/kubernetes-dashboard/kubernetes-dashboard-crb.yaml -n kubernetes-dashboard \
  --dry-run=client -o yaml | kubectl apply -f -      

kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=kubernetes-dashboard  \
   -n kubernetes-dashboard

kubectl -n kubernetes-dashboard describe secret  \
  $(kubectl -n kubernetes-dashboard get secret | grep kubernetes-dashboard-token | awk '{print $1}')      

echo ""
echo "token for kubernetes-dashboard login"

echo "Application URL https://kubernetes-dashboard.local"