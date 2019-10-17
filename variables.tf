variable "env" {
  description = "Environment name"
}

variable "platform_config" {
  description = "Platform configuration"
  type        = "map"
  default     = {}
}

variable "release" {
  type        = "map"
  description = "Metadata about the release"
}

variable "secrets" {
  type        = "map"
  description = "Secret credentials fetched using credstash"
  default     = {}
}

variable "common_application_environment" {
  description = "Environment parameters passed to the container for all environments"
  type        = "map"
  default     = {}
}

variable "application_environment" {
  description = "Environment specific parameters passed to the container"
  type        = "map"
  default     = {}
}

variable "ecs_cluster" {
  type        = "string"
  description = "The ECS cluster"
  default     = "default"
}

variable "port" {
  type        = "string"
  description = "The port that container will be running on"
}

variable "cpu" {
  type        = "string"
  description = "CPU unit reservation for the container"
}

variable "memory" {
  type        = "string"
  description = "The memory reservation for the container in megabytes"
}

variable "nofile_soft_ulimit" {
  type        = "string"
  description = "The soft ulimit for the number of files in container"
  default     = "4096"
}

variable "desired_count" {
  description = "The number of instances of the task definition to place and keep running."
  type        = "string"
  default     = "3"
}

variable "name_suffix" {
  description = "Set a suffix that will be applied to the name in order that a component can have multiple services per environment"
  type        = "string"
  default     = ""
}

variable "target_group_arn" {
  description = "The ALB target group for the service."
  type        = "string"
}

variable "logentries_token" {
  description = "The Logentries token used to be able to get logs sent to a specific log set."
  type        = "string"
  default     = ""
}

variable "task_role_policy" {
  description = "IAM policy document to apply to the tasks via a task role"
  type        = "string"

  default = <<END
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:GetCallerIdentity",
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
END
}

variable "assume_role_policy" {
  description = "A valid IAM policy for assuming roles - optional"
  type        = "string"
  default     = ""
}

variable "taskdef_volume" {
  description = "Map containing 'name' and 'host_path' used to add a volume mapping to the taskdef."
  type        = "map"
  default     = {}
}

variable "container_mountpoint" {
  description = "Map containing 'sourceVolume', 'containerPath' and 'readOnly' (optional) to map a volume into a container."
  type        = "map"
  default     = {}
}

variable "container_port_mappings" {
  description = "JSON document containing an array of port mappings for the container defintion - if set port is ignored (optional)."
  default     = ""
  type        = "string"
}

variable "container_labels" {
  description = "Additional docker labels to apply to the container."
  type        = "map"
  default     = {}
}

variable "deployment_minimum_healthy_percent" {
  description = "The minimumHealthyPercent represents a lower limit on the number of your service's tasks that must remain in the RUNNING state during a deployment, as a percentage of the desiredCount (rounded up to the nearest integer)."
  default     = "100"
}

variable "deployment_maximum_percent" {
  description = "The maximumPercent parameter represents an upper limit on the number of your service's tasks that are allowed in the RUNNING or PENDING state during a deployment, as a percentage of the desiredCount (rounded down to the nearest integer)."
  default     = "200"
}

variable "log_subscription_arn" {
  description = "To enable logging to a kinesis stream"
  default     = ""
}

variable "allow_overnight_scaledown" {
  description = "Allow service to be scaled down"
  default     = false
}

variable "overnight_scaledown_min_count" {
  description = "Minimum task count overnight"
  default     = "0"
}

variable "overnight_scaledown_start_hour" {
  description = "From when a service can be scaled down (Hour in UTC)"
  default     = "22"
}

variable "overnight_scaledown_end_hour" {
  description = "When to bring service back to full strength (Hour in UTC)"
  default     = "06"
}

variable "application_secrets" {
  description = "A list of application specific secret names that can be found in aws secrets manager"
  type        = "list"
  default     = []
}

variable "platform_secrets" {
  description = "A list of common secret names for \"the platform\" that can be found in secrets manager"
  type        = "list"
  default     = []
}

variable "enable_cloudwatch_logs" {
  description = "Enabled ECS log shipping to cloudwatch using awslogs"
  type        = "string"
  default     = "false"
}
