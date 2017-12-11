#!/bin/bash
package=$0

# api-antagonist
# amateur-screenwriter
# studio
# genre-romcom-screenwriter


function usage {
    echo
    echo "    Usage: Deploy a service to kubernetes cluster"
    echo " "
    echo
    echo "    $package [-h|--help] --service=[[JOB_NAME - see below]] --type=[cloud|local]"
    echo " "
    echo "    options:"
    echo "        -h, --help                         show brief help"
    echo "        --service=[esandospopulator]   specify the service to deploy"
    echo "        --type=[cloud|local]               specify whether this is a 'cloud' or 'local' deployment"
    echo
}

while test $# -gt 0; do
        case "$1" in
                -h|--help)
                        usage
                        exit 0
                        ;;
                --service*)
                        export serviceToDeploy=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        echo "Deploying ... ${serviceToDeploy}"
                        if [[  ${serviceToDeploy} != "esandospopulator" && \
                               ${serviceToDeploy} != "test-populator"
                         ]]; then
                            echo "ERROR: Job to deploy must be one of 'esandospopulator'"
                            exit 1
                        fi
                        ;;
                --type*)
                        export deploymentType=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                *)
                        break
                        ;;
        esac
done

if [[ ${serviceToDeploy} == "" || ${deploymentType} == "" ]]; then
    usage
    exit 1
fi

curr_dir=`pwd`

job_dir=`mktemp -d` && cd ${job_dir}
git clone git@github.com:SudoStream/job_${serviceToDeploy}.git
cd job_${serviceToDeploy}

build_version_in_quotes=`cat build.sbt  | grep "version :=" | awk '{print $3}'  `
build_version_stripped=`echo ${build_version_in_quotes:1:-1} `

cd ${curr_dir}
rm -rf ${job_dir}

# bump the label number
oldNum=`cat dev/kubernetes-${serviceToDeploy}-job.yaml | grep bump | cut -d "-" -f2`
newNum=`expr $oldNum + 1`
sed -i "s/bump-$oldNum/bump-$newNum/g" dev/kubernetes-${serviceToDeploy}-job.yaml

################## update the image version of service to latest ####################################
#image_version="eu.gcr.io\/time-to-teach-zone\/${serviceToDeploy}:${build_version_stripped}"
#sed_command="/.*image.*${serviceToDeploy}.*/  s/image:.*$/image: ${image_version}/g"
#sed -i "${sed_command}" dev/kubernetes-${serviceToDeploy}-job.yaml
#####################################################################################################

if [[ ${deploymentType} == "local" ]]; then
    echo "-----------------------------------'local'"
    accessToken=`gcloud auth print-access-token`
    kubectl delete secret myregistrykey
    kubectl create secret docker-registry myregistrykey --docker-server=https://eu.gcr.io \
                    --docker-username=oauth2accesstoken \
                    --docker-password=${accessToken} --docker-email=andy@timetoteach.zone
elif [[ ${deploymentType} == "cloud" ]]; then
    echo "-----------------------------------'local'"
    gcloud container clusters get-credentials timetoteach-dev-cluster

    git add dev/kubernetes-${serviceToDeploy}-job.yaml
    git commit -m "bump"
    git push -u origin master
else
    echo "ERROR: must specify 'local' or 'cloud' run"
    exit 1
fi

kubectl delete job ${serviceToDeploy}
if [[ ${deploymentType} == "local" ]]; then
    kubectl delete deployment ${serviceToDeploy}
    kubectl apply -f ./local/kubernetes-${serviceToDeploy}-job.yaml --record
else
    kubectl apply -f ./dev/kubernetes-${serviceToDeploy}-job.yaml --record
fi
