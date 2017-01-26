#!/usr/bin/env bash

gcloud container clusters get-credentials api-event-horizon-cluster
./scriptwriter-bump.sh

git add dev/kubernetes-scriptwriter-deployment.yaml
git commit -m "bump"
git push -u origin master

kubectl delete secret scriptwriter-tls
kubectl create secret generic scriptwriter-tls --from-file $HOME/.ssh/certs
kubectl delete configmap nginx-scriptwriter-dev-proxf-conf
kubectl create configmap nginx-scriptwriter-dev-proxf-conf --from-file ./dev/nginx-scriptwriter.conf
kubectl apply -f ./dev/kubernetes-scriptwriter-service.yaml --record
kubectl apply -f ./dev/kubernetes-scriptwriter-deployment.yaml --record

