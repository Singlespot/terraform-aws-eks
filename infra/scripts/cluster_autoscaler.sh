#!/bin/bash
helm3 repo add stable https://kubernetes-charts.storage.googleapis.com
helm3 repo update
helm3 upgrade --install cluster-autoscaler stable/cluster-autoscaler \
      --namespace kube-system \
      --set rbac.create=true \
      --set cloudProvider=aws \
      --set awsRegion=$1 \
      --set autoDiscovery.enabled=true \
      --set autoDiscovery.clusterName=$2
