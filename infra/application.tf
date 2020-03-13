locals {
  kubeconfig              = module.eks.kubeconfig_filename
  metrics_path            = "scripts/metrics.sh"
  dashboard_path          = "scripts/dashboard.sh"
  dashboard_url           = "https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml"
  dashboard_k8s_path      = "k8s/dashboard/eks-admin-service-account.yaml"
  prometheus_path         = "scripts/prometheus.sh"
  cluster_autoscaler_path = "scripts/cluster_autoscaler.sh"
}

resource "null_resource" "deploy_metrics" {
  triggers = {
    script_md5 = filemd5(local.metrics_path)
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local.kubeconfig
    }
    command = local.metrics_path
  }
}

resource "null_resource" "deploy_dashboard" {
  depends_on = [null_resource.deploy_metrics]
  triggers = {
    dashboard_url = local.dashboard_url
    yaml_md5      = filemd5(local.dashboard_k8s_path)
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local.kubeconfig
    }
    command = "${local.dashboard_path} ${local.dashboard_url} ${local.dashboard_k8s_path}"
  }
}

resource "null_resource" "deploy_prometheus" {
  triggers = {
    yaml_md5 = filemd5(local.prometheus_path)
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local.kubeconfig
    }
    command = local.prometheus_path
  }
}

resource "null_resource" "deploy_cluster_autoscaler" {
  triggers = {
    yaml_md5      = filemd5(local.cluster_autoscaler_path)
    region        = var.region
    cluster_name  = var.cluster_name
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local.kubeconfig
    }
    command = "${local.cluster_autoscaler_path} ${var.region} ${var.cluster_name}"
  }
}

// helm3 install stable/cluster-autoscaler --values=path/to/your/values-file.yaml
//awsRegion: us-west-2
//
//rbac:
//  create: true
//  serviceAccountAnnotations:
//    eks.amazonaws.com/role-arn: "arn:aws:iam::<ACCOUNT ID>:role/cluster-autoscaler"
//
//autoDiscovery:
//  clusterName: test-eks-irsa
//  enabled: true
