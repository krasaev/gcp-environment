Init environment:

1. Clone the repo into gcloud shell
2. cd gcp-environment/initial-infrastructure
3. chmod +x init.sh destroy.sh
4. ./init.sh "{ORG_NAME}" "{ORG_APP_ID}" "{ORG_APP_PRIVATE_KEY}"
5. copy jenkins url/creds

Destroy

1. ./destroy.sh

Service monitoring

For spring boot expose /actuator/prometheus and add the label and port name to a service

```yaml
labels:
  monitor: spring-actuator-prometheus-monitor
  ...
  ports:
    - name: http
```

TODO:

1. fix todos
2. fix efk cert generation
3. polish init/destroy scripts
4. gke nodes must not use public ip's, cloud nat
5. add cloud armor
6. configure efk
7. switch interservice communication to https
8. enable registry
9. make external services ip static
10. http redirect to https(https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest, https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features#https_redirect)