<h1>terraform&gcp playground</h1>

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

- fix todos
- polish init/destroy scripts
- gke nodes must not use public ip's, cloud nat
- add cloud armor
- configure filebeat
- switch interservice communication to https
- enable registry
- make external services ip static/use single ip
- add SA to jenkins agent
- custom jenkins agent
