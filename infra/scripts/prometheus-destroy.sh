#!/bin/bash
helm3 uninstall prometheus
kubectl delete namespace prometheus
