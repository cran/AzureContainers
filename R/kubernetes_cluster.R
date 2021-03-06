#' Kubernetes cluster class
#'
#' Class representing a [Kubernetes](https://kubernetes.io/docs/home/) cluster. Note that this class can be used to interface with any Docker registry that supports the HTTP V2 API, not just those created via the Azure Container Registry service. Use the [kubernetes_cluster] function to instantiate new objects of this class.
#'
#' @docType class
#' @section Methods:
#' The following methods are available, in addition to those provided by the [AzureRMR::az_resource] class:
#' - `new(...)`: Initialize a new registry object. See 'Initialization' below.
#' - `create_registry_secret(registry, secret_name, email)`: Provide authentication secret for a Docker registry. See 'Secrets' below.
#' - `delete_registry_secret(secret_name)`: Delete a registry authentication secret.
#' - `create(file, ...)`: Creates a deployment or service from a file, using `kubectl create -f`.
#' - `get(type, ...)`: Get information about resources, using `kubectl get`.
#' - `run(name, image, ...)`: Run an image using `kubectl run --image`.
#' - `expose(name, type, file, ...)`: Expose a service using `kubectl expose`. If the `file` argument is provided, read service information from there.
#' - `delete(type, name, file, ...)`: Delete a resource (deployment or service) using `kubectl delete`. If the `file` argument is provided, read resource information from there.
#' - `apply(file, ...)`: Apply a configuration file, using `kubectl apply -f`.
#' - `show_dashboard(port, ...)`: Display the cluster dashboard. By default, use local port 30000.
#' - `kubectl(cmd, ...)`: Run an arbitrary `kubectl` command on this cluster. Called by the other methods above.
#' - `helm(cmd, ...)`: Run a `helm` command on this cluster.
#'
#' @section Initialization:
#' The `new()` method takes one argument: `config`, the name of the file containing the configuration details for the cluster. This should be a YAML or JSON file in the standard Kubernetes configuration format. Set this to NULL to use the default `~/.kube/config` file.
#'
#' @section Secrets:
#' The recommended way to allow a cluster to authenticate with a Docker registry is to give its service principal the appropriate role-based access. However, you can also authenticate with a username and password. To do this, call the `create_registry_secret` method with the following arguments:
#' - `registry`: An object of class either [acr] representing an Azure Container Registry service, or [DockerRegistry] representing the registry itself.
#' - `secret_name`: The name to give the secret. Defaults to the name of the registry server.
#' - `email`: The email address for the Docker registry.
#'
#' @section Kubectl and helm:
#' The methods for this class call the `kubectl` and `helm` commandline tools, passing the `--config` option to specify the configuration information for the cluster. This allows all the features supported by Kubernetes to be available immediately and with a minimum of effort, although it does require that the tools be installed. The returned object from a call to `kubectl` or `helm` will contain the following components:
#' - `status`: The exit status. If this is `NA`, then the process was killed and had no exit status.
#' - `stdout`: The standard output of the command, in a character scalar.
#' - `stderr`: The standard error of the command, in a character scalar.
#' - `timeout`: Whether the process was killed because of a timeout.
#' - `cmdline`: The command line.
#'
#' The first four components are from `processx::run`; AzureContainers adds the last to make it easier to construct scripts that can be run outside R.
#'
#' @seealso
#' [aks], [call_kubectl], [call_helm]
#'
#' [Kubectl commandline reference](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands)
#'
#' @examples
#' \dontrun{
#'
#' rg <- AzureRMR::get_azure_login()$
#'     get_subscription("subscription_id")$
#'     get_resource_group("rgname")
#'
#' # get the cluster endpoint
#' kubclus <- rg$get_aks("mycluster")$get_cluster()
#'
#' # get registry authentication secret
#' kubclus$create_registry_secret(rg$get_acr("myregistry"))
#'
#' # deploy a service
#' kubclus$create("deployment.yaml")
#'
#' # deploy a service from an Internet URL
#' kubclus$create("https://example.com/deployment.yaml")
#'
#' # can also supply the deployment parameters inline
#' kubclus$create("
#' apiVersion: extensions/v1beta1
#' kind: Deployment
#' metadata:
#'   name: model1
#' spec:
#'   replicas: 1
#'   template:
#'     metadata:
#'       labels:
#'         app: model1
#'     spec:
#'       containers:
#'       - name: model1
#'         image: myregistry.azurecr.io/model1
#'         ports:
#'         - containerPort: 8000
#'       imagePullSecrets:
#'       - name: myregistry.azurecr.io
#' ---
#' apiVersion: v1
#' kind: Service
#' metadata:
#'   name: model1-svc
#' spec:
#'   selector:
#'     app: model1
#'   type: LoadBalancer
#'   ports:
#'   - protocol: TCP
#'     port: 8000")
#'
#' # track status
#' kubclus$get("deployment")
#' kubclus$get("service")
#'
#' }
#' @export
KubernetesCluster <- R6::R6Class("KubernetesCluster",

public=list(

    initialize=function(config=NULL)
    {
        private$config <- config
    },

    create_registry_secret=function(registry, secret_name=registry$server$hostname, email, ...)
    {
        if(is_acr(registry))
            registry <- registry$get_docker_registry(as_admin=TRUE)

        if(!is_docker_registry(registry))
            stop("Must supply a Docker registry object", call.=FALSE)

        if(is.null(registry$username) || is.null(registry$password))
            stop("Docker registry object does not contain a username/password", call.=FALSE)

        cmd <- paste0("create secret docker-registry ", secret_name,
                      " --docker-server=", registry$server$hostname,
                      " --docker-username=", registry$username,
                      " --docker-password=", registry$password,
                      " --docker-email=", email)

        self$kubectl(cmd, ...)
    },

    delete_registry_secret=function(secret_name, ...)
    {
        cmd <- paste0("delete secret ", secret_name)
        self$kubectl(cmd, ...)
    },

    run=function(name, image, options="", ...)
    {
        cmd <- paste0("run ", name,
                      " --image ", image,
                      " ", options)
        self$kubectl(cmd, ...)
    },

    expose=function(name, type=c("pod", "service", "replicationcontroller", "deployment", "replicaset"),
                    file=NULL, options="", ...)
    {
        if(is.null(file))
        {
            type <- match.arg(type)
            cmd <- paste0("expose ", type,
                          " ", name,
                          " ", options)
        }
        else
        {
            cmd <- paste0("expose -f ", make_file(file, ".yaml"),
                          " ", options)
        }
        self$kubectl(cmd, ...)
    },

    create=function(file, options="", ...)
    {
        cmd <- paste0("create -f ", make_file(file, ".yaml"),
                      " ", options)
        self$kubectl(cmd, ...)
    },

    apply=function(file, options="", ...)
    {
        cmd <- paste0("apply -f ", make_file(file, ".yaml"),
                      " ", options)
        self$kubectl(cmd, ...)
    },

    delete=function(type, name, file=NULL, options="", ...)
    {
        if(is.null(file))
        {
            cmd <- paste0("delete ", type,
                          " ", name,
                          " ", options)
        }
        else
        {
            cmd <- paste0("delete -f ", make_file(file, ".yaml"),
                          " ", options)
        }
        self$kubectl(cmd, ...)
    },

    get=function(type, options="", ...)
    {
        cmd <- paste0("get ", type,
                      " ", options)
        self$kubectl(cmd, ...)
    },

    show_dashboard=function(port=30000, options="", ...)
    {
        cmd <- paste0("proxy --port=", port,
                      " ", options)
        config <- if(!is.null(private$config))
            paste0("--kubeconfig=", private$config)
        else NULL

        processx::process$new(.AzureContainers$kubectl, c(strsplit(cmd, " ", fixed=TRUE)[[1]], config), ...)
        url <- paste0("http://localhost:",
            port,
            "/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/#!/overview")
        message("If the dashboard does not appear, enter the URL '", url, "' in your browser")
        browseURL(url)
    },

    kubectl=function(cmd="", ...)
    {
        call_kubectl(cmd, config=private$config, ...)
    },

    helm=function(cmd="", ...)
    {
        call_helm(cmd, config=private$config, ...)
    }
),

private=list(
    config=NULL
))


#' Create a new Kubernetes cluster object
#'
#' @param config The name of the file containing the configuration details for the cluster. This should be a YAML or JSON file in the standard Kubernetes configuration format. Set this to NULL to use the default `~/.kube/config` file.
#' @details
#' Use this function to instantiate a new object of the `KubernetesCluster` class, for interacting with a Kubernetes cluster.
#' @return
#' An R6 object of class `KubernetesCluster`.
#'
#' @seealso
#' [KubernetesCluster] for methods for working with the cluster, [call_kubectl], [call_helm]
#'
#' [docker_registry] for the corresponding function to create a Docker registry object
#'
#' @examples
#' \dontrun{
#'
#' kubernetes_cluster()
#' kubernetes_cluster("myconfig.yaml")
#'
#' }
#' @export
kubernetes_cluster <- function(config=NULL)
{
    KubernetesCluster$new(config)
}


# generate a file from a character vector to be passed to kubectl
make_file <- function(file, ext="")
{
    if(length(file) == 1 && (file.exists(file) || is_url(file)))
        return(file)

    out <- tempfile(fileext=ext)
    writeLines(file, out)
    out
}
