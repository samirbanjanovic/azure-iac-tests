$az_alerts = az monitor metrics alert list | ConvertFrom-Json
$tf_resources = [System.Collections.ArrayList]@()

function Get-DimensionsTerraform($dim) {
    $dimensions = $dim | ForEach-Object {
        "`r`ndimension {
            name = `"$($_.name)`"
            operator = `"$($_.operator)`"
            values = [ $([string]::Join(', ', ($_.values | ForEach-Object { "``"$_``"" }))) ]
        }"        
    }

    return $dimensions
}

for ($i = 0; $i -lt $az_alerts.count; $i++) {
    $alert = $az_alerts[$i]
    $resourceName = $alert.criteria.allOf[0].metricName

    $criteria = $alert.criteria.allOf | ForEach-Object {                
        "`r`ncriteria {
            metric_namespace = `"$($_.metricNamespace)`"
            metric_name = `"$($_.metricName)`"
            aggregation = `"$($_.timeAggregation)`"
            threshold = `"$($_.threshold)`"
            operator = `"$($_.operator)`"
            skip_metric_validation = $($_.skipMetricValidation.ToString().ToLower())   
            $(Get-DimensionsTerraform($_.dimensions))
        }"
    }

    $alert_resource = "resource `"azurerm_monitor_metric_alert`" `"$($resourceName)`" {
        name = `"$($alert.name)`"
        resource_group_name = azurerm_resource_group.default.name
        scopes = [ azurerm_kubernetes_cluster.default.id ]
        description = `"$($alert.description.Trim())`"
        enabled = true
        $($criteria)         
    }`r`n"
    $tf_resources.Add($alert_resource)
}

$tf_resources > alerts.tf
terraform fmt .\alerts.tf