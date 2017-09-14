#!/usr/bin/env bash


kubectl delete secret mongodbkeystore
kubectl create secret generic mongodbkeystore --from-file=cacerts=/etc/ssl/cacerts
kubectl delete secret kafkasecrets
kubectl create secret generic kafkasecrets --from-file=kafkabootstrapservers=$HOME/.secrets/kafkabootstrapservers
kubectl delete secret mongoconnectionuri
kubectl create secret generic mongoconnectionuri --from-file=mongoconnectionuri=$HOME/.secrets/mongoconnectionuri
