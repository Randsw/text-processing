#!/usr/bin/env bash

set -e

helm upgrade --install --wait --timeout 35m --atomic --namespace victoria-logs --create-namespace  \
  --repo https://victoriametrics.github.io/helm-charts vls victoria-logs-single --values - <<EOF
server:
  ingress:
    enabled: true
    ingressClassName: nginx
    hosts:
      - name: vl.kind.cluster
        path:
          - /
        port: http
  vmServiceScrape:
    enabled: true
vector:
  enabled: true
  tolerations:
    - key: node-role.kubernetes.io/control-plane
      operator: "Exists"
      effect: "NoSchedule"
  podMonitor:
    enabled: true
dashboards:
  enabled: true
  labels:
    grafana_dashboard: "1"
EOF

cat << 'EOF' | kubectl apply -f -
apiVersion: v1
data:
  vls-logs-dashboard.json: |-
    {
      "annotations": {
        "list": [
          {
            "builtIn": 1,
            "datasource": {
              "type": "prometheus",
              "uid": "PE8D8DB4BEE4E4B22"
            },
            "enable": true,
            "hide": true,
            "iconColor": "rgba(0, 211, 255, 1)",
            "name": "Annotations & Alerts",
            "target": {
              "limit": 100,
              "matchAny": false,
              "tags": [],
              "type": "dashboard"
            },
            "type": "dashboard"
          },
          {
            "datasource": {
              "type": "victoriametrics-logs-datasource",
              "uid": "${ds}"
            },
            "enable": true,
            "hide": false,
            "iconColor": "red",
            "mappings": {
              "text": {
                "source": "field",
                "value": "limits_exceed_errors"
              },
              "time": {
                "source": "field",
                "value": "Time"
              },
              "title": {
                "source": "field",
                "value": "Limits exceed errors"
              }
            },
            "name": "Limits exceed errors",
            "target": {
              "editorMode": "code",
              "expr": "kubernetes.pod_namespace:in($namespace) kubernetes.pod_name:in($pod) kubernetes.container_name:in($container) \n| \"exceeds\"\n| stats count() limits_exceed_errors",
              "legendFormat": "",
              "queryType": "statsRange",
              "refId": "Anno"
            }
          }
        ]
      },
      "editable": true,
      "fiscalYearStartMonth": 0,
      "graphTooltip": 1,
      "id": 362,
      "links": [],
      "panels": [
        {
          "collapsed": false,
          "gridPos": {
            "h": 1,
            "w": 24,
            "x": 0,
            "y": 0
          },
          "id": 16,
          "panels": [],
          "title": "Stats ($namespace:$pod)",
          "type": "row"
        },
        {
          "datasource": {
            "type": "prometheus",
            "uid": "P4169E866C3094E38"
          },
          "fieldConfig": {
            "defaults": {
              "color": {
                "mode": "thresholds"
              },
              "mappings": [],
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {
                    "color": "green",
                    "value": 0
                  }
                ]
              },
              "unit": "short"
            },
            "overrides": []
          },
          "gridPos": {
            "h": 4,
            "w": 3,
            "x": 0,
            "y": 1
          },
          "id": 18,
          "options": {
            "colorMode": "value",
            "graphMode": "area",
            "justifyMode": "auto",
            "orientation": "auto",
            "percentChangeColorMode": "standard",
            "reduceOptions": {
              "calcs": [
                "lastNotNull"
              ],
              "fields": "",
              "values": false
            },
            "showPercentChange": false,
            "textMode": "auto",
            "wideLayout": true
          },
          "pluginVersion": "12.1.1",
          "targets": [
            {
              "datasource": {
                "type": "victorialogs-datasource",
                "uid": "P566C6523BE02F42C"
              },
              "editorMode": "code",
              "expr": "count by (namespace) (kube_pod_info{namespace=~\"$namespace\"})",
              "queryType": "stats",
              "refId": "A"
            }
          ],
          "title": "Total namespaces",
          "type": "stat"
        },
        {
          "datasource": {
            "default": false,
            "type": "victorialogs-datasource",
            "uid": "${ds}"
          },
          "fieldConfig": {
            "defaults": {
              "color": {
                "mode": "thresholds"
              },
              "mappings": [],
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {
                    "color": "green",
                    "value": 0
                  }
                ]
              },
              "unit": "short"
            },
            "overrides": []
          },
          "gridPos": {
            "h": 4,
            "w": 3,
            "x": 3,
            "y": 1
          },
          "id": 19,
          "options": {
            "colorMode": "value",
            "graphMode": "area",
            "justifyMode": "auto",
            "orientation": "auto",
            "percentChangeColorMode": "standard",
            "reduceOptions": {
              "calcs": [
                "lastNotNull"
              ],
              "fields": "",
              "values": false
            },
            "showPercentChange": false,
            "textMode": "auto",
            "wideLayout": true
          },
          "pluginVersion": "12.1.1",
          "targets": [
            {
              "datasource": {
                "type": "victorialogs-datasource",
                "uid": "P566C6523BE02F42C"
              },
              "editorMode": "code",
              "expr": "kubernetes.pod_namespace:in($namespace) kubernetes.pod_name:in($pod)\n| stats by(kubernetes.pod_name) count() \n| count()",
              "queryType": "stats",
              "refId": "A"
            }
          ],
          "title": "Total pods",
          "type": "stat"
        },
        {
          "datasource": {
            "default": false,
            "type": "victorialogs-datasource",
            "uid": "${ds}"
          },
          "fieldConfig": {
            "defaults": {
              "color": {
                "mode": "thresholds"
              },
              "mappings": [],
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {
                    "color": "green",
                    "value": 0
                  }
                ]
              },
              "unit": "short"
            },
            "overrides": []
          },
          "gridPos": {
            "h": 4,
            "w": 3,
            "x": 6,
            "y": 1
          },
          "id": 17,
          "options": {
            "colorMode": "value",
            "graphMode": "area",
            "justifyMode": "auto",
            "orientation": "auto",
            "percentChangeColorMode": "standard",
            "reduceOptions": {
              "calcs": [
                "sum"
              ],
              "fields": "",
              "values": false
            },
            "showPercentChange": false,
            "textMode": "auto",
            "wideLayout": true
          },
          "pluginVersion": "12.1.1",
          "targets": [
            {
              "datasource": {
                "type": "victorialogs-datasource",
                "uid": "P566C6523BE02F42C"
              },
              "editorMode": "code",
              "expr": "kubernetes.pod_namespace:in($namespace) kubernetes.pod_name:in($pod) kubernetes.container_name:in($container)\n| stats count() ",
              "queryType": "statsRange",
              "refId": "A"
            }
          ],
          "title": "Total logs",
          "type": "stat"
        },
        {
          "datasource": {
            "default": false,
            "type": "victorialogs-datasource",
            "uid": "${ds}"
          },
          "description": "Here, _time: $__range  needs to be removed later, once ??gh_issue?? is implemented",
          "fieldConfig": {
            "defaults": {
              "color": {
                "mode": "thresholds"
              },
              "mappings": [],
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {
                    "color": "green",
                    "value": 0
                  }
                ]
              }
            },
            "overrides": []
          },
          "gridPos": {
            "h": 4,
            "w": 9,
            "x": 9,
            "y": 1
          },
          "id": 12,
          "options": {
            "minVizHeight": 75,
            "minVizWidth": 75,
            "orientation": "auto",
            "reduceOptions": {
              "calcs": [
                "lastNotNull"
              ],
              "fields": "",
              "values": false
            },
            "showThresholdLabels": false,
            "showThresholdMarkers": true,
            "sizing": "auto"
          },
          "pluginVersion": "12.1.1",
          "targets": [
            {
              "datasource": {
                "type": "victorialogs-datasource",
                "uid": "P566C6523BE02F42C"
              },
              "editorMode": "code",
              "expr": "kubernetes.pod_namespace:in($namespace) kubernetes.pod_name:in($pod) kubernetes.container_name:in($container)\n| format if (log.level:\"\") \"other\" as log.level\n| stats by (log.level) count() \n| sort desc",
              "hide": false,
              "legendFormat": "{{log.level}}",
              "queryType": "stats",
              "refId": "A"
            }
          ],
          "timeFrom": "24h",
          "title": "Logs by log.level by last 24h",
          "type": "gauge"
        },
        {
          "datasource": {
            "default": false,
            "type": "victorialogs-datasource",
            "uid": "${ds}"
          },
          "description": "",
          "fieldConfig": {
            "defaults": {
              "color": {
                "mode": "thresholds"
              },
              "mappings": [],
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {
                    "color": "green",
                    "value": 0
                  }
                ]
              }
            },
            "overrides": []
          },
          "gridPos": {
            "h": 8,
            "w": 9,
            "x": 0,
            "y": 5
          },
          "id": 24,
          "options": {
            "displayMode": "lcd",
            "legend": {
              "calcs": [],
              "displayMode": "list",
              "placement": "bottom",
              "showLegend": false
            },
            "maxVizHeight": 300,
            "minVizHeight": 16,
            "minVizWidth": 8,
            "namePlacement": "auto",
            "orientation": "horizontal",
            "reduceOptions": {
              "calcs": [
                "lastNotNull"
              ],
              "fields": "",
              "values": false
            },
            "showUnfilled": true,
            "sizing": "auto",
            "valueMode": "color"
          },
          "pluginVersion": "12.1.1",
          "targets": [
            {
              "datasource": {
                "type": "victorialogs-datasource",
                "uid": "P566C6523BE02F42C"
              },
              "editorMode": "code",
              "expr": "kubernetes.pod_namespace:in($namespace) kubernetes.pod_name:in($pod) kubernetes.container_name:in($container)\n| format if (kubernetes.pod_namespace:\"\") \"unknown\" as kubernetes.pod_namespace\n| stats by (kubernetes.pod_namespace) count() total\n| sort by(total) desc \n| limit 5",
              "hide": false,
              "legendFormat": "{{kubernetes.pod_namespace}}",
              "queryType": "stats",
              "refId": "A"
            }
          ],
          "title": "Logs by namespace",
          "type": "bargauge"
        },
        {
          "datasource": {
            "default": false,
            "type": "victorialogs-datasource",
            "uid": "${ds}"
          },
          "description": "",
          "fieldConfig": {
            "defaults": {
              "color": {
                "mode": "thresholds"
              },
              "mappings": [],
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {
                    "color": "green",
                    "value": 0
                  }
                ]
              }
            },
            "overrides": []
          },
          "gridPos": {
            "h": 8,
            "w": 9,
            "x": 9,
            "y": 5
          },
          "id": 23,
          "options": {
            "displayMode": "lcd",
            "legend": {
              "calcs": [],
              "displayMode": "list",
              "placement": "bottom",
              "showLegend": false
            },
            "maxVizHeight": 300,
            "minVizHeight": 16,
            "minVizWidth": 8,
            "namePlacement": "auto",
            "orientation": "horizontal",
            "reduceOptions": {
              "calcs": [
                "lastNotNull"
              ],
              "fields": "",
              "values": false
            },
            "showUnfilled": true,
            "sizing": "auto",
            "valueMode": "color"
          },
          "pluginVersion": "12.1.1",
          "targets": [
            {
              "datasource": {
                "type": "victorialogs-datasource",
                "uid": "P566C6523BE02F42C"
              },
              "editorMode": "code",
              "expr": "kubernetes.pod_namespace:in($namespace) kubernetes.pod_name:in($pod) kubernetes.container_name:in($container)\n| format if (log.level:\"\") \"other\" as log.level\n| stats by (log.level) count() total\n| sort by(total) desc ",
              "hide": false,
              "legendFormat": "{{log.level}}",
              "queryType": "stats",
              "refId": "A"
            }
          ],
          "title": "Logs by log.level",
          "type": "bargauge"
        },
        {
          "collapsed": false,
          "gridPos": {
            "h": 1,
            "w": 24,
            "x": 0,
            "y": 13
          },
          "id": 10,
          "panels": [],
          "title": "Stats by pod ($namespace:$pod:$filter)",
          "type": "row"
        },
        {
          "datasource": {
            "default": false,
            "type": "victorialogs-datasource",
            "uid": "${ds}"
          },
          "description": "Shows the most common field-value pairs \n\nhttps://docs.victoriametrics.com/victorialogs/logsql/#facets-pipe",
          "fieldConfig": {
            "defaults": {
              "color": {
                "mode": "thresholds"
              },
              "custom": {
                "align": "auto",
                "cellOptions": {
                  "type": "auto"
                },
                "inspect": false
              },
              "mappings": [],
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {
                    "color": "green",
                    "value": 0
                  },
                  {
                    "color": "red",
                    "value": 80
                  }
                ]
              }
            },
            "overrides": [
              {
                "matcher": {
                  "id": "byName",
                  "options": "Time"
                },
                "properties": [
                  {
                    "id": "custom.hidden",
                    "value": true
                  }
                ]
              },
              {
                "matcher": {
                  "id": "byName",
                  "options": "hits"
                },
                "properties": [
                  {
                    "id": "custom.width",
                    "value": 85
                  }
                ]
              },
              {
                "matcher": {
                  "id": "byName",
                  "options": "field_value"
                },
                "properties": [
                  {
                    "id": "custom.width",
                    "value": 227
                  }
                ]
              }
            ]
          },
          "gridPos": {
            "h": 7,
            "w": 10,
            "x": 0,
            "y": 14
          },
          "id": 26,
          "options": {
            "cellHeight": "sm",
            "footer": {
              "countRows": false,
              "fields": "",
              "reducer": [
                "sum"
              ],
              "show": false
            },
            "showHeader": true,
            "sortBy": []
          },
          "pluginVersion": "12.1.1",
          "targets": [
            {
              "datasource": {
                "type": "victorialogs-datasource",
                "uid": "P566C6523BE02F42C"
              },
              "editorMode": "code",
              "expr": "kubernetes.pod_namespace:in($namespace) kubernetes.pod_name:in($pod) kubernetes.container_name:in($container)\n| $filter\n| facets 3\n| sort by(hits) desc",
              "legendFormat": "",
              "queryType": "instant",
              "refId": "A"
            }
          ],
          "title": "Top field-value pairs (facets)",
          "transformations": [
            {
              "id": "extractFields",
              "options": {
                "format": "auto",
                "keepTime": true,
                "replace": true,
                "source": "labels"
              }
            }
          ],
          "type": "table"
        },
        {
          "datasource": {
            "default": false,
            "type": "victorialogs-datasource",
            "uid": "${ds}"
          },
          "description": "Shows most common log patterns on the time range\n\nhttps://docs.victoriametrics.com/victorialogs/logsql/#collapse_nums-pipe",
          "fieldConfig": {
            "defaults": {
              "color": {
                "mode": "thresholds"
              },
              "custom": {
                "align": "auto",
                "cellOptions": {
                  "type": "auto"
                },
                "inspect": false
              },
              "mappings": [],
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {
                    "color": "green",
                    "value": 0
                  },
                  {
                    "color": "red",
                    "value": 80
                  }
                ]
              }
            },
            "overrides": [
              {
                "matcher": {
                  "id": "byName",
                  "options": "Time"
                },
                "properties": [
                  {
                    "id": "custom.hidden",
                    "value": true
                  }
                ]
              },
              {
                "matcher": {
                  "id": "byName",
                  "options": "labels"
                },
                "properties": [
                  {
                    "id": "custom.hidden",
                    "value": true
                  }
                ]
              },
              {
                "matcher": {
                  "id": "byName",
                  "options": "Line"
                },
                "properties": [
                  {
                    "id": "custom.width",
                    "value": 991
                  }
                ]
              }
            ]
          },
          "gridPos": {
            "h": 7,
            "w": 14,
            "x": 10,
            "y": 14
          },
          "id": 25,
          "options": {
            "cellHeight": "sm",
            "footer": {
              "countRows": false,
              "fields": "",
              "reducer": [
                "sum"
              ],
              "show": false
            },
            "showHeader": true,
            "sortBy": []
          },
          "pluginVersion": "12.1.1",
          "targets": [
            {
              "datasource": {
                "type": "victorialogs-datasource",
                "uid": "P566C6523BE02F42C"
              },
              "editorMode": "code",
              "expr": "kubernetes.pod_namespace:in($namespace) kubernetes.pod_name:in($pod) kubernetes.container_name:in($container)\n| $filter\n| collapse_nums prettify\n| top 10 by(_msg)",
              "legendFormat": "",
              "queryType": "instant",
              "refId": "A"
            }
          ],
          "title": "Top 10 log patterns (collapse_nums)",
          "transformations": [
            {
              "id": "extractFields",
              "options": {
                "format": "auto",
                "keepTime": false,
                "replace": false,
                "source": "labels"
              }
            }
          ],
          "type": "table"
        },
        {
          "datasource": {
            "default": false,
            "type": "victorialogs-datasource",
            "uid": "${ds}"
          },
          "fieldConfig": {
            "defaults": {
              "color": {
                "mode": "palette-classic"
              },
              "custom": {
                "axisBorderShow": false,
                "axisCenteredZero": false,
                "axisColorMode": "text",
                "axisLabel": "",
                "axisPlacement": "auto",
                "barAlignment": 0,
                "barWidthFactor": 0.6,
                "drawStyle": "line",
                "fillOpacity": 0,
                "gradientMode": "none",
                "hideFrom": {
                  "legend": false,
                  "tooltip": false,
                  "viz": false
                },
                "insertNulls": false,
                "lineInterpolation": "linear",
                "lineWidth": 1,
                "pointSize": 5,
                "scaleDistribution": {
                  "type": "linear"
                },
                "showPoints": "auto",
                "spanNulls": false,
                "stacking": {
                  "group": "A",
                  "mode": "none"
                },
                "thresholdsStyle": {
                  "mode": "off"
                }
              },
              "mappings": [],
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {
                    "color": "green",
                    "value": 0
                  },
                  {
                    "color": "red",
                    "value": 80
                  }
                ]
              },
              "unit": "logs/s"
            },
            "overrides": []
          },
          "gridPos": {
            "h": 10,
            "w": 10,
            "x": 0,
            "y": 21
          },
          "id": 13,
          "options": {
            "legend": {
              "calcs": [
                "lastNotNull",
                "mean"
              ],
              "displayMode": "table",
              "placement": "bottom",
              "showLegend": true,
              "sortBy": "Mean",
              "sortDesc": true
            },
            "tooltip": {
              "hideZeros": false,
              "mode": "single",
              "sort": "none"
            }
          },
          "pluginVersion": "12.1.1",
          "targets": [
            {
              "datasource": {
                "type": "victorialogs-datasource",
                "uid": "P566C6523BE02F42C"
              },
              "editorMode": "code",
              "expr": "kubernetes.pod_namespace:in($namespace) kubernetes.pod_name:in($pod) kubernetes.container_name:in($container)\n| $filter\n| stats by (kubernetes.pod_name,kubernetes.container_name) rate() logs_rate\n| filter logs_rate: > 0",
              "legendFormat": "{{kubernetes.pod_name}} ({{kubernetes.container_name}})",
              "queryType": "statsRange",
              "refId": "A"
            }
          ],
          "title": "Logs rate ($pod)",
          "type": "timeseries"
        },
        {
          "datasource": {
            "default": false,
            "type": "victorialogs-datasource",
            "uid": "${ds}"
          },
          "fieldConfig": {
            "defaults": {
              "color": {
                "mode": "palette-classic"
              },
              "custom": {
                "axisBorderShow": false,
                "axisCenteredZero": false,
                "axisColorMode": "text",
                "axisLabel": "",
                "axisPlacement": "auto",
                "fillOpacity": 80,
                "gradientMode": "none",
                "hideFrom": {
                  "legend": false,
                  "tooltip": false,
                  "viz": false
                },
                "lineWidth": 1,
                "scaleDistribution": {
                  "type": "linear"
                },
                "thresholdsStyle": {
                  "mode": "off"
                }
              },
              "mappings": [],
              "thresholds": {
                "mode": "absolute",
                "steps": [
                  {
                    "color": "green",
                    "value": 0
                  },
                  {
                    "color": "red",
                    "value": 80
                  }
                ]
              }
            },
            "overrides": [
              {
                "__systemRef": "hideSeriesFrom",
                "matcher": {
                  "id": "byNames",
                  "options": {
                    "mode": "exclude",
                    "names": [
                      "vmanomaly-node-exporter-victoria-metrics-anomaly-68cc7f94b6vwvt (model)"
                    ],
                    "prefix": "All except:",
                    "readOnly": true
                  }
                },
                "properties": []
              }
            ]
          },
          "gridPos": {
            "h": 10,
            "w": 14,
            "x": 10,
            "y": 21
          },
          "id": 8,
          "interval": "10m",
          "options": {
            "barRadius": 0,
            "barWidth": 1,
            "fullHighlight": false,
            "groupWidth": 0.7,
            "legend": {
              "calcs": [],
              "displayMode": "list",
              "placement": "bottom",
              "showLegend": false
            },
            "orientation": "vertical",
            "showValue": "auto",
            "stacking": "normal",
            "tooltip": {
              "hideZeros": false,
              "mode": "multi",
              "sort": "desc"
            },
            "xTickLabelRotation": 0,
            "xTickLabelSpacing": 200
          },
          "pluginVersion": "12.1.1",
          "targets": [
            {
              "datasource": {
                "type": "victorialogs-datasource",
                "uid": "P566C6523BE02F42C"
              },
              "editorMode": "code",
              "expr": "kubernetes.pod_namespace:in($namespace) kubernetes.pod_name:in($pod) kubernetes.container_name:in($container)\n| $filter\n| stats by (kubernetes.pod_name,kubernetes.container_name) count() logs_total",
              "legendFormat": "{{kubernetes.pod_name}} ({{kubernetes.container_name}})",
              "queryType": "statsRange",
              "refId": "A"
            }
          ],
          "title": "Logs total ($pod)",
          "type": "barchart"
        },
        {
          "collapsed": false,
          "gridPos": {
            "h": 1,
            "w": 24,
            "x": 0,
            "y": 31
          },
          "id": 27,
          "panels": [],
          "title": "Raw logs",
          "type": "row"
        },
        {
          "datasource": {
            "default": false,
            "type": "victorialogs-datasource",
            "uid": "${ds}"
          },
          "fieldConfig": {
            "defaults": {},
            "overrides": []
          },
          "gridPos": {
            "h": 13,
            "w": 24,
            "x": 0,
            "y": 32
          },
          "id": 1,
          "maxPerRow": 12,
          "options": {
            "dedupStrategy": "none",
            "enableLogDetails": true,
            "prettifyLogMessage": false,
            "showCommonLabels": false,
            "showLabels": false,
            "showTime": false,
            "sortOrder": "Descending",
            "wrapLogMessage": false
          },
          "pluginVersion": "11.3.1",
          "repeat": "limit",
          "repeatDirection": "h",
          "targets": [
            {
              "datasource": {
                "type": "victorialogs-datasource",
                "uid": "P566C6523BE02F42C"
              },
              "editorMode": "code",
              "expr": "kubernetes.pod_namespace:in($namespace) kubernetes.pod_name:in($pod) kubernetes.container_name:in($container)\n| $filter\n| sort by (_time)\n| limit $limit",
              "queryType": "instant",
              "refId": "A"
            }
          ],
          "title": "pod logs",
          "type": "logs"
        }
      ],
      "preload": false,
      "refresh": "",
      "schemaVersion": 41,
      "tags": [
        "demo"
      ],
      "templating": {
        "list": [
          {
            "current": {
              "text": "slack2logs-vm",
              "value": "P566C6523BE02F42C"
            },
            "includeAll": false,
            "label": "ds",
            "name": "ds",
            "options": [],
            "query": "victoriametrics-logs-datasource",
            "refresh": 1,
            "regex": "",
            "type": "datasource"
          },
          {
            "allValue": ".*",
            "current": {
              "text": [
                "slack2logs",
                "vmlogs",
                "vm-operator"
              ],
              "value": [
                "slack2logs",
                "vmlogs",
                "vm-operator"
              ]
            },
            "datasource": {
              "type": "victorialogs-datasource",
              "uid": "${ds}"
            },
            "definition": "",
            "includeAll": true,
            "multi": true,
            "name": "namespace",
            "options": [],
            "query": {
              "field": "kubernetes.pod_namespace",
              "limit": 50,
              "query": "",
              "refId": "VictoriaLogsVariableQueryEditor-VariableQuery",
              "type": "fieldValue"
            },
            "refresh": 1,
            "regex": "",
            "type": "query"
          },
          {
            "allValue": "*",
            "current": {
              "text": "All",
              "value": [
                "$__all"
              ]
            },
            "datasource": {
              "type": "victorialogs-datasource",
              "uid": "${ds}"
            },
            "definition": "kubernetes.pod_namespace: in($namespace)",
            "includeAll": true,
            "multi": true,
            "name": "pod",
            "options": [],
            "query": {
              "field": "kubernetes.pod_name",
              "limit": 1001,
              "query": "kubernetes.pod_namespace: in($namespace)",
              "refId": "VictoriaLogsVariableQueryEditor-VariableQuery",
              "type": "fieldValue"
            },
            "refresh": 1,
            "regex": "",
            "type": "query"
          },
          {
            "allValue": "*",
            "current": {
              "text": "All",
              "value": "$__all"
            },
            "datasource": {
              "type": "victorialogs-datasource",
              "uid": "P566C6523BE02F42C"
            },
            "definition": "kubernetes.pod_namespace: in($namespace) and kubernetes.pod_name: in($pod)",
            "includeAll": true,
            "multi": true,
            "name": "container",
            "options": [],
            "query": {
              "field": "kubernetes.container_name",
              "limit": 100,
              "query": "kubernetes.pod_namespace: in($namespace) and kubernetes.pod_name: in($pod)",
              "refId": "VictoriaLogsVariableQueryEditor-VariableQuery",
              "type": "fieldValue"
            },
            "refresh": 1,
            "regex": "",
            "type": "query"
          },
          {
            "current": {
              "text": "*",
              "value": "*"
            },
            "description": "Custom LogsQL filter attached to every query.\nType any word or phrase you want to look for. Set to \"*\" to not filter.\nSee https://docs.victoriametrics.com/victorialogs/logsql/#word-filter ",
            "name": "filter",
            "options": [
              {
                "selected": true,
                "text": "*",
                "value": "*"
              }
            ],
            "query": "*",
            "type": "textbox"
          },
          {
            "current": {
              "text": "100",
              "value": "100"
            },
            "description": "Limit number of entries in Logs panel",
            "includeAll": false,
            "name": "limit",
            "options": [
              {
                "selected": true,
                "text": "100",
                "value": "100"
              },
              {
                "selected": false,
                "text": "500",
                "value": "500"
              },
              {
                "selected": false,
                "text": "1000",
                "value": "1000"
              },
              {
                "selected": false,
                "text": "2000",
                "value": "2000"
              }
            ],
            "query": "100, 500, 1000, 2000",
            "type": "custom"
          },
          {
            "baseFilters": [],
            "datasource": {
              "type": "victorialogs-datasource",
              "uid": "${ds}"
            },
            "filters": [],
            "name": "Filters",
            "type": "adhoc"
          }
        ]
      },
      "time": {
        "from": "now-24h",
        "to": "now"
      },
      "timepicker": {},
      "timezone": "browser",
      "title": "K8s logs via VictoriaLogs",
      "uid": "be5zidev72m80f",
      "version": 1
    }
kind: ConfigMap
metadata:
  name: vls-dashboard
  namespace: victoria-logs
  labels:
    grafana_dashboard: "1"
EOF