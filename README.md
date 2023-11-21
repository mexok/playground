Playground
==========

This project should showcase the integration of Azure, Terraform, Helm,
Kubernetes and Spark with a little PySpark examples.

Azure free subscription is sufficient for running this example.


Setup CLI tools
---------------

Install the following tools:
 * helm
 * kubectl
 * azurecli
 * terraform


Setup Terraform Azure credentials
---------------------------------

Follow this guide to get your Azure credentials: https://developer.hashicorp.com/terraform/tutorials/azure-get-started/azure-build

Copy them into `terraform-azure/azure_credentials.sh`:

```
export ARM_CLIENT_ID="<APPID_VALUE>"
export ARM_CLIENT_SECRET="<PASSWORD_VALUE>"
export ARM_SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"
export ARM_TENANT_ID="<TENANT_VALUE>"
```

Copy them also into into `terraform-azure/terraform.tfvars`:

```
appId    = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
password = "mySecretPassword"
```


Setup domain
------------

To setup a domain register or use an existing one with your domain provider of
choice. For this test setup, I am using 'pyspark.de', but you can use your own
by replacing all occurances of 'pyspark.de' with your own in the file
`cluster-deploy/kubernetes/ingress.yaml`

Also make sure you change the email from 'konstantin@semerker.de' to your own in
the file `cluster-deploy/kubernetes/letsencrypt.yaml`


Setup the cluster
-----------------

1. Navigate inside terraform-azure and execute:

```
terraform apply
```

2. Setup kubectl to work with the cluster, e.g. via:

```
# Source: https://learn.microsoft.com/en-us/azure/aks/tutorial-kubernetes-deploy-cluster?tabs=azure-cli
az aks get-credentials --resource-group myResourceGroup --name myCluster
```

3. Install spark via helm:

```
# see also: https://artifacthub.io/packages/helm/bitnami/spark
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-spark bitnami/spark --version 8.1.1
```

4. Install ingress-nginx for routing http traffik:

```
# Source: https://learn.microsoft.com/en-us/azure/aks/ingress-basic?tabs=azure-cli
NAMESPACE=ingress-basic
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --create-namespace \
  --namespace $NAMESPACE \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz
```

5. Setup cert-manager to issue tls certificates via letsencrypt

```
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml
```

6. Setup kubernetes resources

Navigate inside cluster-deploy/kubernetes and execute following command:

```
kubectl apply -f .
```

7. Set the AAAA record for your domain to the kubernetes load balancer one.


Troubleshooting
---------------

If you run into issues with tls certification, this will be most likely
caused by the certificate not being available at the startup during
nginx-ingress. You can easily fix this by finding the corresponding nginx pod
and deleting it manually. Kubernetes will automatically recreate it which will
cause retry of the certificate finding process. If this doesn't help you can
always try 'kubectl logs ...'

To delete the ingress pod use:
```
# replace with your correct pod
kubectl delete po ingress-nginx-controller-6c99b8c6b6-gbf7f -n ingress-basic
```


Running the examples
--------------------

The examples are located in pyspark-examples.

For execution, open an interactive pyspark shell via the commands in
`pyspark-examples/exec_pyspark_shall.sh`

Execute the test code using the interactive shell.


Additional notes
----------------

Helm values can be exported via following command for additional custimization:

```
helm show values bitnami/spark >helm-spark-values.override.yaml
```

Things not implemented (and I have currently no intention of fixing):

 - Persistent public ip: The idea here is to fixate the public ip address of the
   load balancer to avoid getting assigned a new ip if the service is recreated.
   As this is just an example, it's ok for me, but should be certainly fixed
   in a production setup.
