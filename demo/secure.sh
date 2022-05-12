#!/usr/bin/env bash -e

kubectl apply -f 01-cert-manager.yaml
until cmctl check api; do sleep 5; done
kubectl apply -n cert-manager -f 02-csi-driver.yaml
kubectl apply -n cert-manager -f 03-trust.yaml
sleep 2
for i in $(kubectl get cr -n cert-manager -o=jsonpath="{.items[*]['metadata.name']}"); do cmctl approve -n cert-manager $i || true; done
while [ "$(kubectl get deployment -n cert-manager cert-manager-trust -o json | jq '.status.availableReplicas')" != "$(kubectl get deployment -n cert-manager cert-manager-trust -o json | jq '.spec.replicas')" ]
do
  echo "waiting for cm trust to start"
  sleep 5
done


kubectl apply -f 04-selfsigned-ca.yaml

sleep 2

for i in $(kubectl get cr -n cert-manager -o=jsonpath="{.items[*]['metadata.name']}"); do cmctl approve -n cert-manager $i || true; done

sleep 2

kubectl apply -n cert-manager -f "05-trust-domain-bundle.yaml"

sleep 2

for i in $(kubectl get cr -o=jsonpath="{.items[*]['metadata.name']}"); do cmctl approve $i || true; done

kubectl apply -f oauth2-proxy-secured.yaml
kubectl apply -f supersecureapp-secure.yaml

sleep 10

for i in $(kubectl get cr -o=jsonpath="{.items[*]['metadata.name']}"); do cmctl approve $i || true; done
