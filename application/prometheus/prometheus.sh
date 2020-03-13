#!/bin/bash
kubectl create namespace prometheus
helm3 install prometheus stable/prometheus \
      --namespace prometheus \
      --set alertmanager.persistentVolume.storageClass="gp2",server.persistentVolume.storageClass="gp2"
