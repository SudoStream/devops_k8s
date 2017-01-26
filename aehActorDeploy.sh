#!/usr/bin/env bash

gcloud container clusters get-credentials api-event-horizon-cluster
./aeh-actor-bump.sh

git add dev/kubernetes-aeh-actor-deployment.yaml
git commit -m "bump"
git push -u origin master

kubectl delete secret scriptwriter-tls
kubectl create secret generic scriptwriter-tls --from-file $HOME/.ssh/certs
kubectl delete configmap nginx-aeh-actor-dev-proxf-conf
kubectl create configmap nginx-aeh-actor-dev-proxf-conf --from-file ./dev/nginx.conf
kubectl apply -f ./dev/kubernetes-aeh-actor-service.yaml --record
kubectl apply -f ./dev/kubernetes-aeh-actor-deployment.yaml --record
