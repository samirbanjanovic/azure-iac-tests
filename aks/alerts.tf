resource "azurerm_monitor_metric_alert" "completedJobsCount" {
  name                = "Jobs completed more than 6 hours ago for k8stest CI-11"
  resource_group_name = azurerm_resource_group.default.name
  scopes              = [azurerm_kubernetes_cluster.default.id]
  description         = "This alert monitors completed jobs (more than 6 hours ago)."
  enabled             = true

  criteria {
    metric_namespace       = "Insights.Container/pods"
    metric_name            = "completedJobsCount"
    aggregation            = "Average"
    threshold              = "0"
    operator               = "GreaterThan"
    skip_metric_validation = true

    dimension {
      name     = "controllerName"
      operator = "Include"
      values   = ["*"]
    }
    dimension {
      name     = "kubernetes namespace"
      operator = "Include"
      values   = ["*"]
    }
  }
}

resource "azurerm_monitor_metric_alert" "nodesCount" {
  name                = "Nodes in not ready status for k8stest CI-3"
  resource_group_name = azurerm_resource_group.default.name
  scopes              = [azurerm_kubernetes_cluster.default.id]
  description         = "Node status monitoring."
  enabled             = true

  criteria {
    metric_namespace       = "Insights.Container/nodes"
    metric_name            = "nodesCount"
    aggregation            = "Average"
    threshold              = "0"
    operator               = "GreaterThan"
    skip_metric_validation = true

    dimension {
      name     = "status"
      operator = "Include"
      values   = ["NotReady"]
    }
  }
}

resource "azurerm_monitor_metric_alert" "PodReadyPercentage" {
  name                = "Pods not in ready state for k8stest CI-8"
  resource_group_name = azurerm_resource_group.default.name
  scopes              = [azurerm_kubernetes_cluster.default.id]
  description         = "This alert monitors pods in the ready state."
  enabled             = true

  criteria {
    metric_namespace       = "Insights.Container/pods"
    metric_name            = "PodReadyPercentage"
    aggregation            = "Average"
    threshold              = "80"
    operator               = "LessThan"
    skip_metric_validation = true

    dimension {
      name     = "controllerName"
      operator = "Include"
      values   = ["*"]
    }
    dimension {
      name     = "kubernetes namespace"
      operator = "Include"
      values   = ["*"]
    }
  }
}

resource "azurerm_monitor_metric_alert" "pvUsageThresholdViolated" {
  name                = "PV usage violates the configured threshold for k8stest CI-21"
  resource_group_name = azurerm_resource_group.default.name
  scopes              = [azurerm_kubernetes_cluster.default.id]
  description         = "This alert monitors PV usage. It uses the threshold defined in the config map."
  enabled             = true

  criteria {
    metric_namespace       = "Insights.Container/persistentvolumes"
    metric_name            = "pvUsageThresholdViolated"
    aggregation            = "Average"
    threshold              = "0"
    operator               = "GreaterThan"
    skip_metric_validation = true

    dimension {
      name     = "podName"
      operator = "Include"
      values   = ["*"]
    }
    dimension {
      name     = "kubernetesNamespace"
      operator = "Include"
      values   = ["*"]
    }
  }
}

resource "azurerm_monitor_metric_alert" "DiskUsedPercentage" {
  name                = "Disk usage high for k8stest CI-5"
  resource_group_name = azurerm_resource_group.default.name
  scopes              = [azurerm_kubernetes_cluster.default.id]
  description         = "This alert monitors disk usage for all nodes and storage devices."
  enabled             = true

  criteria {
    metric_namespace       = "Insights.Container/nodes"
    metric_name            = "DiskUsedPercentage"
    aggregation            = "Average"
    threshold              = "80"
    operator               = "GreaterThan"
    skip_metric_validation = true

    dimension {
      name     = "host"
      operator = "Include"
      values   = ["*"]
    }
    dimension {
      name     = "device"
      operator = "Include"
      values   = ["*"]
    }
  }
}

resource "azurerm_monitor_metric_alert" "memoryWorkingSetPercentage" {
  name                = "Node working set memory utilization high for k8stest CI-2"
  resource_group_name = azurerm_resource_group.default.name
  scopes              = [azurerm_kubernetes_cluster.default.id]
  description         = "Node working set memory utilization across the cluster."
  enabled             = true

  criteria {
    metric_namespace       = "Insights.Container/nodes"
    metric_name            = "memoryWorkingSetPercentage"
    aggregation            = "Average"
    threshold              = "80"
    operator               = "GreaterThan"
    skip_metric_validation = true

    dimension {
      name     = "host"
      operator = "Include"
      values   = ["*"]
    }
  }
}

resource "azurerm_monitor_metric_alert" "cpuUsagePercentage" {
  name                = "Node CPU utilization high for k8stest CI-1"
  resource_group_name = azurerm_resource_group.default.name
  scopes              = [azurerm_kubernetes_cluster.default.id]
  description         = "Node CPU utilization across the cluster."
  enabled             = true

  criteria {
    metric_namespace       = "Insights.Container/nodes"
    metric_name            = "cpuUsagePercentage"
    aggregation            = "Average"
    threshold              = "80"
    operator               = "GreaterThan"
    skip_metric_validation = true

    dimension {
      name     = "host"
      operator = "Include"
      values   = ["*"]
    }
  }
}

resource "azurerm_monitor_metric_alert" "podCount" {
  name                = "Pods in failed state for k8stest CI-4"
  resource_group_name = azurerm_resource_group.default.name
  scopes              = [azurerm_kubernetes_cluster.default.id]
  description         = "Pod status monitoring."
  enabled             = true

  criteria {
    metric_namespace       = "Insights.Container/pods"
    metric_name            = "podCount"
    aggregation            = "Average"
    threshold              = "0"
    operator               = "GreaterThan"
    skip_metric_validation = true

    dimension {
      name     = "phase"
      operator = "Include"
      values   = ["Failed"]
    }
  }
}

resource "azurerm_monitor_metric_alert" "memoryWorkingSetThresholdViolated" {
  name                = "Container working set memory usage violates the configured threshold for k8stest CI-20"
  resource_group_name = azurerm_resource_group.default.name
  scopes              = [azurerm_kubernetes_cluster.default.id]
  description         = "This alert monitors container working set memory usage. It uses the threshold defined in the config map."
  enabled             = true

  criteria {
    metric_namespace       = "Insights.Container/containers"
    metric_name            = "memoryWorkingSetThresholdViolated"
    aggregation            = "Average"
    threshold              = "0"
    operator               = "GreaterThan"
    skip_metric_validation = true

    dimension {
      name     = "controllerName"
      operator = "Include"
      values   = ["*"]
    }
    dimension {
      name     = "kubernetes namespace"
      operator = "Include"
      values   = ["*"]
    }
  }
}

resource "azurerm_monitor_metric_alert" "oomKilledContainerCount" {
  name                = "Containers getting OOM killed for k8stest CI-6"
  resource_group_name = azurerm_resource_group.default.name
  scopes              = [azurerm_kubernetes_cluster.default.id]
  description         = "This alert monitors number of containers killed due to out of memory(OOM) error."
  enabled             = true

  criteria {
    metric_namespace       = "Insights.Container/pods"
    metric_name            = "oomKilledContainerCount"
    aggregation            = "Average"
    threshold              = "0"
    operator               = "GreaterThan"
    skip_metric_validation = true

    dimension {
      name     = "kubernetes namespace"
      operator = "Include"
      values   = ["*"]
    }
    dimension {
      name     = "controllerName"
      operator = "Include"
      values   = ["*"]
    }
  }
}

resource "azurerm_monitor_metric_alert" "cpuThresholdViolated" {
  name                = "Container CPU usage violates the configured threshold for k8stest CI-19"
  resource_group_name = azurerm_resource_group.default.name
  scopes              = [azurerm_kubernetes_cluster.default.id]
  description         = "This alert monitors container CPU usage. It uses the threshold defined in the config map."
  enabled             = true

  criteria {
    metric_namespace       = "Insights.Container/containers"
    metric_name            = "cpuThresholdViolated"
    aggregation            = "Average"
    threshold              = "0"
    operator               = "GreaterThan"
    skip_metric_validation = true

    dimension {
      name     = "controllerName"
      operator = "Include"
      values   = ["*"]
    }
    dimension {
      name     = "kubernetes namespace"
      operator = "Include"
      values   = ["*"]
    }
  }
}

resource "azurerm_monitor_metric_alert" "restartingContainerCount" {
  name                = "Restarting container count for k8stest CI-7"
  resource_group_name = azurerm_resource_group.default.name
  scopes              = [azurerm_kubernetes_cluster.default.id]
  description         = "This alert monitors number of containers restarting across the cluster."
  enabled             = true

  criteria {
    metric_namespace       = "Insights.Container/pods"
    metric_name            = "restartingContainerCount"
    aggregation            = "Average"
    threshold              = "0"
    operator               = "GreaterThan"
    skip_metric_validation = true

    dimension {
      name     = "kubernetes namespace"
      operator = "Include"
      values   = ["*"]
    }
    dimension {
      name     = "controllerName"
      operator = "Include"
      values   = ["*"]
    }
  }
}

