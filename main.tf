locals {
  service_name = "${var.env}-${lookup(var.release, "component")}"
}

module "ecs_update_monitor" {
  source = "github.com/mergermarket/tf_ecs_update_monitor"

  cluster = "${var.ecs_cluster}"
  service = "${module.service.name}"
  taskdef = "${module.taskdef.arn}"
}

module "service" {
  source = "github.com/mergermarket/tf_load_balanced_ecs_service?ref=no-target-group"

  name                               = "${local.service_name}${var.name_suffix}"
  cluster                            = "${var.ecs_cluster}"
  task_definition                    = "${module.taskdef.arn}"
  container_name                     = "${lookup(var.release, "component")}${var.name_suffix}"
  container_port                     = "${var.port}"
  desired_count                      = "${var.desired_count}"
  target_group_arn                   = "${var.target_group_arn}"
  deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"
  deployment_maximum_percent         = "${var.deployment_maximum_percent}"
}

module "taskdef" {
  source = "github.com/mergermarket/tf_ecs_task_definition_with_task_role"

  family                = "${local.service_name}${var.name_suffix}"
  container_definitions = ["${module.service_container_definition.rendered}"]
  policy                = "${var.task_role_policy}"
  assume_role_policy    = "${var.assume_role_policy}"
  volume                = "${var.taskdef_volume}"
  env                   = "${var.env}"
  release               = "${var.release}"
}

module "service_container_definition" {
  source = "github.com/fewstera/tf_ecs_container_definition"

  name                   = "${lookup(var.release, "component")}${var.name_suffix}"
  image                  = "${lookup(var.release, "image_id")}"
  cpu                    = "${var.cpu}"
  memory                 = "${var.memory}"
  container_port         = "${var.port}"
  nofile_soft_ulimit     = "${var.nofile_soft_ulimit}"
  mountpoint             = "${var.container_mountpoint}"
  port_mappings          = "${var.container_port_mappings}"
  application_secrets    = "${var.application_secrets}"
  platform_secrets       = "${var.platform_secrets}"
  enable_cloudwatch_logs = "${var.enable_cloudwatch_logs}"

  container_env = "${merge(
    map(
      "ENV_NAME", "${var.env}",
      "COMPONENT_NAME", "${lookup(var.release, "component")}",
      "VERSION", "${lookup(var.release, "version")}"
    ),
    var.common_application_environment,
    var.application_environment,
    var.secrets
  )}"

  labels = "${merge(map(
    "component", var.release["component"],
    "env", var.env,
    "team", var.release["team"],
    "version", var.release["version"],
  ), var.container_labels)}"
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${local.service_name}"
  retention_in_days = "7"
}

resource "aws_cloudwatch_log_subscription_filter" "kinesis_log_ecs_logs_stream" {
  count           = "${var.platform_config["datadog_log_subscription_arn"] != "" ? 1 : 0}"
  name            = "kinesis-log-ecs-stream-${local.service_name}"
  destination_arn = "${var.platform_config["datadog_log_subscription_arn"]}"
  log_group_name  = "/ecs/${local.service_name}"
  filter_pattern  = ""
  depends_on      = ["aws_cloudwatch_log_group.ecs_logs"]
}

resource "aws_appautoscaling_target" "ecs" {
  count              = "${var.allow_overnight_scaledown}"
  min_capacity       = "${var.desired_count}"
  max_capacity       = "${var.desired_count}"
  resource_id        = "service/${var.ecs_cluster}/${local.service_name}${var.name_suffix}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_scheduled_action" "scale_down" {
  count              = "${var.allow_overnight_scaledown}"
  name               = "scale_down"
  service_namespace  = "${aws_appautoscaling_target.ecs.service_namespace}"
  resource_id        = "${aws_appautoscaling_target.ecs.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.ecs.scalable_dimension}"
  schedule           = "cron(*/30 ${var.overnight_scaledown_start_hour}-${(var.overnight_scaledown_end_hour) - 1} ? * * *)"

  scalable_target_action {
    min_capacity = "${var.overnight_scaledown_min_count}"
    max_capacity = "${var.overnight_scaledown_min_count}"
  }
}

resource "aws_appautoscaling_scheduled_action" "scale_back_up" {
  count              = "${var.allow_overnight_scaledown}"
  name               = "scale_up"
  service_namespace  = "${aws_appautoscaling_target.ecs.service_namespace}"
  resource_id        = "${aws_appautoscaling_target.ecs.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.ecs.scalable_dimension}"
  schedule           = "cron(10 ${var.overnight_scaledown_end_hour} ? * MON-FRI *)"

  scalable_target_action {
    min_capacity = "${var.desired_count}"
    max_capacity = "${var.desired_count}"
  }
}
