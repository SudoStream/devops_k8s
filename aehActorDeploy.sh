#!/usr/bin/env bash
shouldskip=$1

if [[ ${shouldskip} != "local" ]]; then
    gcloud container clusters get-credentials api-event-horizon-cluster

    oldNum=`cat dev/kubernetes-aeh-actor-deployment.yaml | grep bump | cut -d "-" -f2`
    newNum=`expr $oldNum + 1`
    sed -i "s/bump-$oldNum/bump-$newNum/g" dev/kubernetes-aeh-actor-deployment.yaml

    git add dev/kubernetes-aeh-actor-deployment.yaml
    git commit -m "bump"
    git push -u origin master
fi

kubectl delete secret scriptwriter-tls
kubectl create secret generic scriptwriter-tls --from-file $HOME/.ssh/certs
kubectl delete configmap nginx-aeh-actor-dev-proxf-conf
kubectl create configmap nginx-aeh-actor-dev-proxf-conf --from-file ./dev/nginx-aeh-actor.conf
kubectl apply -f ./dev/kubernetes-aeh-actor-service.yaml --record
kubectl apply -f ./dev/kubernetes-aeh-actor-deployment.yaml --record
