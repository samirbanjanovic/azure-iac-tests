# Generate random resource group name
resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}

resource "random_id" "log_analytics_workspace_name_suffix" {
  byte_length = 8
}

resource "azurerm_log_analytics_workspace" "test" {
  location            = var.log_analytics_workspace_location
  # The WorkSpace name has to be unique across the whole of azure;
  # not just the current subscription/tenant.
  name                = "${var.log_analytics_workspace_name}-${random_id.log_analytics_workspace_name_suffix.dec}"
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = var.log_analytics_workspace_sku
}

resource "azurerm_log_analytics_solution" "test" {
  location              = azurerm_log_analytics_workspace.test.location
  resource_group_name   = azurerm_resource_group.rg.name
  solution_name         = "ContainerInsights"
  workspace_name        = azurerm_log_analytics_workspace.test.name
  workspace_resource_id = azurerm_log_analytics_workspace.test.id

  plan {
    product   = "OMSGallery/ContainerInsights"
    publisher = "Microsoft"
  }
}

resource "azapi_resource" "monitor_workspace" {
  type = "Microsoft.Monitor/accounts@2021-06-03-preview"
  name = "azurek8s-insights-ws"
  location = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id
  body = jsonencode({})
}

resource "azurerm_kubernetes_cluster" "k8s" {
  location            = azurerm_resource_group.rg.location
  name                = var.cluster_name
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix
  tags                = {
    Environment = "Development"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "Standard_D2_v2"
    node_count = var.agent_count
  }

  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.test.id        
  }
}

# see https://learn.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-custom-metrics?tabs=cli#enable-custom-metrics
# The preview feature for role assignment this will be added automatically.
# For now we need to ad it manually.
# The id is hard to find, it is part of the "oms_agent" output attribute and was moved from addon_profiles in the later version of the providers.
# Use object_id and specify check AAD otherwise it will go into an infinite loop.
# https://github.com/hashicorp/terraform-provider-azurerm/pull/7056
resource "azurerm_role_assignment" "omsagent-aks" {
  scope                            = azurerm_kubernetes_cluster.k8s.id
  role_definition_name             = "Monitoring Metrics Publisher"
  principal_id                     = azurerm_kubernetes_cluster.k8s.oms_agent[0].oms_agent_identity[0].object_id
  skip_service_principal_aad_check = false
}

resource "azurerm_monitor_metric_alert" "completedJobsCount" {
  name                = "Jobs completed more than 6 hours ago for k8stest CI-11"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_kubernetes_cluster.k8s.id]
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

resource "azurerm_monitor_metric_alert" "cpuThresholdViolated" {
  name                = "Container CPU usage violates the configured threshold for k8stest CI-19"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_kubernetes_cluster.k8s.id]
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

resource "azurerm_monitor_metric_alert" "cpuUsagePercentage" {
  name                = "Node CPU utilization high for k8stest CI-1"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_kubernetes_cluster.k8s.id]
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
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_kubernetes_cluster.k8s.id]
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
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_kubernetes_cluster.k8s.id]
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

resource "azurerm_monitor_metric_alert" "DiskUsedPercentage" {
  name                = "Disk usage high for k8stest CI-5"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_kubernetes_cluster.k8s.id]
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

resource "azurerm_monitor_metric_alert" "nodesCount" {
  name                = "Nodes in not ready status for k8stest CI-3"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_kubernetes_cluster.k8s.id]
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

resource "azurerm_monitor_metric_alert" "memoryWorkingSetPercentage" {
  name                = "Node working set memory utilization high for k8stest CI-2"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_kubernetes_cluster.k8s.id]
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

resource "azurerm_monitor_metric_alert" "oomKilledContainerCount" {
  name                = "Containers getting OOM killed for k8stest CI-6"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_kubernetes_cluster.k8s.id]
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

resource "azurerm_monitor_metric_alert" "pvUsageThresholdViolated" {
  name                = "PV usage violates the configured threshold for k8stest CI-21"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_kubernetes_cluster.k8s.id]
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

resource "azurerm_monitor_metric_alert" "PodReadyPercentage" {
  name                = "Pods not in ready state for k8stest CI-8"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_kubernetes_cluster.k8s.id]
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

resource "azurerm_monitor_metric_alert" "restartingContainerCount" {
  name                = "Restarting container count for k8stest CI-7"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_kubernetes_cluster.k8s.id]
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

