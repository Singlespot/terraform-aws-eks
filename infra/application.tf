locals {
  kubeconfig                      = module.eks.kubeconfig_filename
  metrics_path                    = "scripts/metrics.sh"
  metrics_destroy_path            = "scripts/metrics-destroy.sh"
  dashboard_path                  = "scripts/dashboard.sh"
  dashboard_destroy_path          = "scripts/dashboard-destroy.sh"
  dashboard_url                   = "https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.4/aio/deploy/recommended.yaml"
  dashboard_k8s_path              = "k8s/dashboard/eks-admin-service-account.yaml"
//  prometheus_path                 = "scripts/prometheus.sh"
//  prometheus_destroy_path         = "scripts/prometheus-destroy.sh"
  cluster_autoscaler_path         = "scripts/cluster_autoscaler.sh"
  cluster_autoscaler_destroy_path = "scripts/cluster_autoscaler-destroy.sh"
  cluster_autoscaler_version      = "v1.18.2"
}

resource "null_resource" "deploy_metrics" {
//  depends_on = [module.eks]
  triggers = {
    script_md5 = filemd5(local.metrics_path)
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local.kubeconfig
    }
    command = local.metrics_path
  }

//  provisioner "local-exec" {
//    when = destroy
//    environment = {
//      KUBECONFIG = local.kubeconfig
//    }
//    command = local.metrics_destroy_path
//  }
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

//  provisioner "local-exec" {
//    when = destroy
//    environment = {
//      KUBECONFIG = local.kubeconfig
//    }
//    command = "${local.dashboard_destroy_path} ${local.dashboard_url} ${local.dashboard_k8s_path}"
//  }
}

//resource "null_resource" "deploy_prometheus" {
//  triggers = {
//    yaml_md5 = filemd5(local.prometheus_path)
//  }
//
//  provisioner "local-exec" {
//    environment = {
//      KUBECONFIG = local.kubeconfig
//    }
//    command = local.prometheus_path
//  }
//
////  provisioner "local-exec" {
////    when = destroy
////    environment = {
////      KUBECONFIG = local.kubeconfig
////    }
////    command = local.prometheus_destroy_path
////  }
//}

resource "null_resource" "deploy_cluster_autoscaler" {
  triggers = {
    yaml_md5      = filemd5(local.cluster_autoscaler_path)
    version       = local.cluster_autoscaler_version
    region        = var.region
    cluster_name  = var.cluster_name
  }

  provisioner "local-exec" {
    environment = {
      KUBECONFIG = local.kubeconfig
    }
    command = "${local.cluster_autoscaler_path} ${local.cluster_autoscaler_version} ${var.region} ${var.cluster_name}"
  }

//  provisioner "local-exec" {
//    when = destroy
//    environment = {
//      KUBECONFIG = local.kubeconfig
//    }
//    command = local.cluster_autoscaler_destroy_path
//  }
}
