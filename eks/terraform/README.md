


# Cluster requirements 


## Monitoring 
- Prometheus Monitoring Stack
    - Node Exporter 
    - Kube state metrics 
- Loki
- FluentD
- Lens 
- Thanos

## DNS
- Nginx Ingress Controller
- Istio/Consul

## Security
- Cert manager 
- Lets Encrypt
- Cert Bot
- Someting for container Scanning 
- Vault 
- key management stor

## CI/CD
- Jenkins 
- Circle Ci
- Gitlab 
    - Datree
    - Docker Rgistry/ECR
    - Nexus 
    - Sonarqube
    - Gradle

- Helm 
- Argo CD



### Command used to spin up Cluster 
aws eks --region eu-west-2 update-kubeconfig --name eks_prod_cluster --profile default


### Useful resources

https://www.youtube.com/watch?v=oYHZ3EPR094