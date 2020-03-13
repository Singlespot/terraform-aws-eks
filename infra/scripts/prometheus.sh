#!/bin/bash
kubectl create namespace prometheus || true
helm3 repo add stable https://kubernetes-charts.storage.googleapis.com
helm3 repo update
helm3 upgrade --install prometheus stable/prometheus \
      --namespace prometheus \
      --set alertmanager.persistentVolume.storageClass="gp2",server.persistentVolume.storageClass="gp2"
