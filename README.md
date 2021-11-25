<h2>Initializing infrastructure:</h2>

1. clone the repo into gcloud shell
2. prepare config file
    ```properties
    domain.name=example.com
    # leave domain.cert.* empty to generate self-signed certificates
    domain.cert.private-key-file=
    domain.cert.public-key-file=
    github.organization.name=example
    github.jenkins.app-id=example
    github.jenkins.private-key-file=./jenkins-github-private-key.key
    ```
3. cd gcp-environment/initial-infrastructure
4. run ./init.sh /path/to/config.properties
5. use provided service's url/creds

<h2>Destroying infrastructure</h2>

1. cd gcp-environment/initial-infrastructure
2. run ./destroy.sh /path/to/config.properties

<h2>Service monitoring:</h2>

For spring boot expose /actuator/prometheus api and add the label and port name to a service

```yaml
labels:
  monitor: spring-actuator-prometheus-monitor
  ...
  ports:
    - name: http
```

TODO:

1. fix todos
3. polish init/destroy scripts
4. gke nodes must not use public ip's, cloud nat
5. add cloud armor
6. configure filebeat
7. switch interservice communication to https
8. enable registry
9. make external services ip static/use single ip