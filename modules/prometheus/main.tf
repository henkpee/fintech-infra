################################################################################
# Prometheus WorkSpace
################################################################################

module "prometheus" {
  source = "terraform-aws-modules/managed-service-prometheus/aws"

  workspace_alias  = "eks-workspace"
  create_workspace = true

  alert_manager_definition = <<-EOT
  alertmanager_config: |
    route:
      receiver: 'default'
    receivers:
      - name: 'default'
  EOT

  rule_group_namespaces = {
    first = {
      name = "rule-01"
      data = <<-EOT
      groups:
        - name: test
          rules:
          - record: metric:recording_rule
            expr: avg(rate(container_cpu_usage_seconds_total[5m]))
      EOT
    }
    second = {
      name = "rule-02"
      data = <<-EOT
      groups:
        - name: test
          rules:
          - record: metric:recording_rule
            expr: avg(rate(container_cpu_usage_seconds_total[5m]))
      EOT
    }
  }
}

################################################################################
# Prometheus Namespace
################################################################################

resource "kubernetes_namespace" "prometheus-namespace" {
  metadata {
    annotations = {
      name = "monitoring"
    }

    labels = {
      application = "monitoring"
    }

    name = "monitoring"
  }
}

################################################################################
# Prometheus Role
################################################################################

resource "aws_iam_role" "prometheus_role" {
  name = "${var.env_name}_prometheus"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_arn, "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/", "")}:sub" = "system:serviceaccount:${kubernetes_namespace.prometheus-namespace.metadata[0].name}:amp-iamproxy-ingest-role"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "prometheus_policy" {
  role       = aws_iam_role.prometheus_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess"
}

################################################################################
# Prometheus Service Account
################################################################################

resource "kubernetes_service_account" "service-account" {
  metadata {
    name      = "amp-iamproxy-ingest-role"
    namespace = kubernetes_namespace.prometheus-namespace.metadata[0].name
    labels = {
      "app.kubernetes.io/name" = "prometheus"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = module.prometheus_role.iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}


################################################################################
# Install Prometheus With Helm
################################################################################

resource "helm_release" "prometheus" {
  name       = "prometheus-community"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  version    = "23.1.0"
  namespace  = kubernetes_namespace.prometheus-namespace.metadata[0].name
  depends_on = [
    kubernetes_service_account.service-account
  ]

  values = [
    "${file("${path.module}/templates/amp_ingest_override_values.yaml")}"
  ]

  set {
    name  = "server.remoteWrite[0].url"
    value = "${module.prometheus.workspace_prometheus_endpoint}api/v1/remote_write"
  }

  set {
    name  = "server.remoteWrite[0].sigv4.region"
    value = var.main-region
  }

}

