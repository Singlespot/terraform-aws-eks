#!/bin/bash
helm3 repo add autoscaler https://kubernetes.github.io/autoscaler
helm3 repo update
helm3 upgrade --namespace kube-system --values k8s/cluster-autoscaler/values.yaml  \
      --set image.tag=$1 \
      --set awsRegion=$2 \
      --set autoDiscovery.clusterName=$3 \
      --install cluster-autoscaler autoscaler/cluster-autoscaler-chart
