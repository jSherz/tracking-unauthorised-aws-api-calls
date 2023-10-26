resource "aws_xray_sampling_rule" "main" {
  rule_name      = local.project_name
  fixed_rate     = 1 # 100%
  host           = "*"
  http_method    = "*"
  priority       = 1000
  reservoir_size = 10
  resource_arn   = "*"
  service_name   = local.project_name
  service_type   = "*"
  url_path       = "*"
  version        = 1
}
