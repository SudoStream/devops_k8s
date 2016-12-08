#!/bin/bash

oldNum=`cat dev/kubernetes-scriptwriter-deployment.yaml | grep bump | cut -d "-" -f2`
newNum=`expr $oldNum + 1`
sed -i "s/bump-$oldNum/bump-$newNum/g" dev/kubernetes-scriptwriter-deployment.yaml
