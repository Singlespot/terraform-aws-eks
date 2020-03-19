#!/bin/bash
helm3 repo add stable https://kubernetes-charts.storage.googleapis.com
helm3 repo update
helm3 upgrade --values k8s/cluster-autoscaler/values.yaml --install cluster-autoscaler stable/cluster-autoscaler \
      --namespace kube-system \
      --set image.tag=$1 \
      --set rbac.create=true \
      --set cloudProvider=aws \
      --set awsRegion=$2 \
      --set autoDiscovery.enabled=true \
      --set autoDiscovery.clusterName=$3
