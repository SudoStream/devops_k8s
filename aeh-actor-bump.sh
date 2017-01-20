#!/bin/bash

oldNum=`cat dev/kubernetes-aeh-actor-deployment.yaml | grep bump | cut -d "-" -f2`
newNum=`expr $oldNum + 1`
sed -i "s/bump-$oldNum/bump-$newNum/g" dev/kubernetes-aeh-actor-deployment.yaml
