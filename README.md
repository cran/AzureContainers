# AzureContainers <img src="man/figures/logo.png" align="right" width=150 />

[![CRAN](https://www.r-pkg.org/badges/version/AzureContainers)](https://cran.r-project.org/package=AzureContainers)
![Downloads](https://cranlogs.r-pkg.org/badges/AzureContainers)
![R-CMD-check](https://github.com/Azure/AzureContainers/workflows/R-CMD-check/badge.svg)

A package for working with [Azure Container Registry (ACR)](https://azure.microsoft.com/en-us/products/container-registry/), [Azure Kubernetes Service (AKS)](https://azure.microsoft.com/en-us/products/kubernetes-service/) and [Azure Container Instances (ACI)](https://azure.microsoft.com/en-us/products/container-instances/). Extends the Azure Resource Manager interface provided by the [AzureRMR](https://github.com/Azure/AzureRMR) package.

AzureContainers lets you build and deploy containerised services in R, using Docker and Kubernetes. For full functionality, you should have [Docker](https://docs.docker.com/install/) installed, as well as the [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) and [helm](https://helm.sh/) commandline tools. Otherwise it is relatively lightweight, requiring neither Powershell nor Python.

Note that AzureContainers can talk to any Docker registry that uses the [V2 HTTP API](https://docs.docker.com/registry/spec/api/), not just those created via ACR. Similarly, it can interface with Kubernetes clusters anywhere, not just those created via AKS.

The primary repo for this package is at https://github.com/Azure/AzureContainers; please submit issues and PRs there. It is also mirrored at the Cloudyr org at https://github.com/cloudyr/AzureContainers. You can install the development version of the package with `devtools::install_github("Azure/AzureContainers")`.

## Example workflow

Here is a sample R workflow to package up an R model as a container, deploy it to a Kubernetes cluster, and expose it as a service.

```r
library(AzureContainers)

az <- AzureRMR::get_azure_login()
resgroup <- az$
    get_subscription("<subscription_id>")$
    create_resource_group("myresgroup", location="australiaeast")

# create container registry
acr <- resgroup$create_acr("myacr", location="australiaeast")

# create Docker image from a predefined Dockerfile
call_docker("build -t newcontainer .")

# get registry endpoint, upload image
reg <- acr$get_docker_registry()
reg$push("newcontainer")


# create Kubernetes cluster with 2 nodes
aks <- resgroup$create_aks("myakscluster",
    location="australiaeast",
    agent_pools=agent_pool("pool1", 2))

# give the cluster pull access to the registry
acr$add_role_assignment(aks, "Acrpull")

# get cluster endpoint, deploy from ACR to AKS with predefined yaml definition file
clus <- aks$get_cluster()
clus$create("model1.yaml")
clus$get("service")
```

---
<p align="center"><a href="https://github.com/Azure/AzureR"><img src="https://github.com/Azure/AzureR/raw/master/images/logo2.png" width=800 /></a></p>
