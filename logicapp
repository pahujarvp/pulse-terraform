{
    "definition": {
        "metadata": {
            "notes": {}
        },
        "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
        "contentVersion": "1.0.0.0",
        "triggers": {
            "When_an_HTTP_request_is_received": {
                "type": "Request",
                "kind": "Http",
                "inputs": {
                    "method": "POST",
                    "schema": {
                        "type": "object",
                        "properties": {
                            "schemaId": {
                                "type": "string"
                            },
                            "data": {
                                "type": "object",
                                "properties": {
                                    "essentials": {
                                        "type": "object",
                                        "properties": {
                                            "alertId": {
                                                "type": "string"
                                            },
                                            "alertRule": {
                                                "type": "string"
                                            },
                                            "severity": {
                                                "type": "string"
                                            },
                                            "description": {
                                                "type": "string"
                                            },
                                            "monitorCondition": {
                                                "type": "string"
                                            },
                                            "alertTargetIDs": {
                                                "type": "array",
                                                "items": {
                                                    "type": "string"
                                                }
                                            },
                                            "firedDateTime": {
                                                "type": "string"
                                            },
                                            "resolvedDateTime": {
                                                "type": "string"
                                            }
                                        },
                                        "required": [
                                            "alertId",
                                            "alertRule",
                                            "monitorCondition"
                                        ]
                                    }
                                },
                                "required": [
                                    "essentials"
                                ]
                            }
                        },
                        "required": [
                            "data"
                        ]
                    }
                }
            }
        },
        "actions": {
            "Check_Alert_Status": {
                "actions": {
                    "Create_Record": {
                        "type": "ApiConnection",
                        "inputs": {
                            "host": {
                                "connection": {
                                    "name": "@parameters('$connections')['service-now']['connectionId']"
                                }
                            },
                            "method": "post",
                            "body": {
                                "impact": "2",
                                "caller_id": "Azure Integration Account",
                                "subcategory": "Memory / CPU",
                                "short_description": "@concat('CPU Alert: ', triggerBody()?['data']?['essentials']?['alertRule'])",
                                "assignment_group": "Incident Management",
                                "description": "@concat('Azure Monitor CPU Alert', decodeUriComponent('%0A'), 'Alert Name: ', triggerBody()?['data']?['essentials']?['alertRule'], decodeUriComponent('%0A'), 'Severity: ', triggerBody()?['data']?['essentials']?['severity'], decodeUriComponent('%0A'), 'Alert Status: ', triggerBody()?['data']?['essentials']?['monitorCondition'], decodeUriComponent('%0A'), 'Alert ID: ', triggerBody()?['data']?['essentials']?['alertId'], decodeUriComponent('%0A'), 'Affected Resource: ', if(empty(triggerBody()?['data']?['essentials']?['alertTargetIDs']), 'Not available', first(triggerBody()?['data']?['essentials']?['alertTargetIDs'])), decodeUriComponent('%0A'), 'Description: ', triggerBody()?['data']?['essentials']?['description'])",
                                "contact_type": "Self-service",
                                "urgency": "1",
                                "correlation_id": "@triggerBody()?['data']?['essentials']?['alertId']",
                                "category": "Performance"
                            },
                            "path": "/api/now/v2/table/@{encodeURIComponent('incident')}"
                        }
                    }
                },
                "runAfter": {},
                "else": {
                    "actions": {
                        "Resolved_Alert_No_Incident": {
                            "type": "Compose",
                            "inputs": "Alert is resolved. No new incident created."
                        }
                    }
                },
                "expression": {
                    "and": [
                        {
                            "equals": [
                                "@triggerBody()?['data']?['essentials']?['monitorCondition']",
                                "Fired"
                            ]
                        }
                    ]
                },
                "type": "If"
            }
        },
        "outputs": {},
        "parameters": {
            "$connections": {
                "type": "Object",
                "defaultValue": {}
            }
        }
    },
    "parameters": {
        "$connections": {
            "type": "Object",
            "value": {
                "service-now": {
                    "id": "/subscriptions/029048c9-25c1-4d71-acfb-58fb9e765f9f/providers/Microsoft.Web/locations/centralindia/managedApis/service-now",
                    "connectionId": "/subscriptions/029048c9-25c1-4d71-acfb-58fb9e765f9f/resourceGroups/rg-healops-workload-cin-01/providers/Microsoft.Web/connections/service-now",
                    "connectionName": "service-now",
                    "connectionProperties": {}
                }
            }
        }
    }
}
