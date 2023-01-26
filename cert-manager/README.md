## Installing the Chart
Full installation instructions, including details on how to configure extra functionality in cert-manager can be found in the .

- https://artifacthub.io/packages/helm/cert-manager/cert-manager

Before installing the chart, you must first install the cert-manager CustomResourceDefinition resources. This is performed in a separate step to allow you to easily uninstall and reinstall cert-manager without deleting your installed custom resources.

```
$ kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.10.1/cert-manager.crds.yaml
```