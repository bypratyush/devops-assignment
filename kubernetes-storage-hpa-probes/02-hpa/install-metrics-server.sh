#!/usr/bin/env bash
# Install metrics-server on the kind cluster so that `kubectl top` and the HPA work.
#
# kind's kubelets serve a self-signed certificate that is not signed by the
# cluster CA, so metrics-server refuses to scrape them unless it is told to skip
# verification with --kubelet-insecure-tls. That flag is fine on a local lab
# cluster and must NOT be used on a real one.
#
# Usage: ./install-metrics-server.sh
set -u
cd "$(dirname "${BASH_SOURCE[0]}")"
hr() { echo; echo "=============================================================="; echo "$*"; echo "=============================================================="; }
VERSION=v0.9.0
URL="https://github.com/kubernetes-sigs/metrics-server/releases/download/$VERSION/components.yaml"

hr "STEP 1 - Before: is there a Metrics API at all?"
echo "\$ kubectl top nodes"
kubectl top nodes 2>&1
echo
echo "\$ kubectl get apiservice v1beta1.metrics.k8s.io"
kubectl get apiservice v1beta1.metrics.k8s.io 2>&1

hr "STEP 2 - Apply the upstream metrics-server manifest ($VERSION)"
kubectl apply -f "$URL"

hr "STEP 3 - Add --kubelet-insecure-tls (kind only)"
kubectl -n kube-system patch deployment metrics-server --type=json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
kubectl -n kube-system rollout status deployment/metrics-server --timeout=180s
echo
kubectl -n kube-system get deployment metrics-server -o jsonpath='{range .spec.template.spec.containers[0].args[*]}  {@}{"\n"}{end}'

hr "STEP 4 - Wait for the APIService to report Available"
kubectl wait --for=condition=Available apiservice/v1beta1.metrics.k8s.io --timeout=180s
kubectl get apiservice v1beta1.metrics.k8s.io

hr "STEP 5 - After: kubectl top works"
# The first scrape needs one --metric-resolution interval (15s) to have data.
for _ in $(seq 1 20); do
  kubectl top nodes >/dev/null 2>&1 && break
  sleep 5
done
echo "\$ kubectl top nodes"
kubectl top nodes 2>&1
echo
echo "\$ kubectl top pods -n kube-system"
kubectl top pods -n kube-system 2>&1

hr "DONE"
