# Monitoring - Captured Output

> **Submitted by:** Pratyush Mohanty  |  **Roll No.:** 24BCS10238

Commands run by hand on 2026-10-08 against the kind cluster `devops-hw`.

```text
$ helm upgrade --install monitoring prometheus-community/kube-prometheus-stack --version 92.1.0 -n monitoring --create-namespace -f kube-prometheus-stack-values.yaml --wait --timeout 8m
Release "monitoring" does not exist. Installing it now.
NAME: monitoring
LAST DEPLOYED: Thu Oct  8 00:10:19 2026
NAMESPACE: monitoring
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
NOTES:
kube-prometheus-stack has been installed. Check its status by running:
  kubectl --namespace monitoring get pods -l "release=monitoring"
Get Grafana 'admin' user password by running:
  kubectl --namespace monitoring get secrets monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo

$ kubectl -n monitoring get pods
NAME                                                   READY   STATUS    RESTARTS   AGE
monitoring-grafana-5bd569fdc7-hwpjv                    3/3     Running   0          2m7s
monitoring-kube-prometheus-operator-7896b4bf77-9p8wb   1/1     Running   0          2m7s
monitoring-kube-state-metrics-5dfd8797f7-7cvfj         1/1     Running   0          2m7s
prometheus-monitoring-kube-prometheus-prometheus-0     2/2     Running   0          119s

$ kubectl apply -f lostfound-alerts.yaml -f lostfound-dashboard.yaml
prometheusrule.monitoring.coreos.com/lostfound-alerts created
configmap/lostfound-dashboard created

$ kubectl -n argocd get application lostfound -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status,REVISION:.status.sync.revision
NAME        SYNC     HEALTH        REVISION
lostfound   Synced   Progressing   62058cf61c0f8a60e59054c61d1a56017388ae27

$ curl -s 'http://localhost:19090/api/v1/targets?state=active' | python3 -c 'import json,sys; [print("  %-55s %s" % (t["scrapePool"], t["health"])) for t in json.load(sys.stdin)["data"]["activeTargets"] if "lostfound" in t["scrapePool"]]'
  serviceMonitor/lostfound/lostfound-backend/0            up
  serviceMonitor/lostfound/lostfound-backend/0            up

```
