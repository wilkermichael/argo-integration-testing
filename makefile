KUBERNETES_VERSION = v1.25.11
CHART_VERSION = 1.3.1
ARGO_REPO=~/dev/argo-rollouts-michael
ARGO_MANIFEST=~/dev/argo-rollouts-michael/manifests/install.yaml
ARGO_DOCKER=wilko1989/argo-rollouts:latest
PLUGIN_DIR=~/dev/rollouts-plugin-trafficrouter-consul

### SETUP KIND CLUSTER WITH CONSUL
# setup sets up the kind cluster and deploys the consul helm chart
setup: kind deploy

kind: kind-delete
	kind create cluster --image kindest/node:$(KUBERNETES_VERSION) --name=dc1 --config ./resources/kind_config.yaml

add-helm-Repo:
	helm repo add hashicorp https://helm.releases.hashicorp.com

# kind-delete deletes the kind cluster dc1
kind-delete:
	kind delete cluster --name=dc1

# deploy deploys the consul helm chart with the values.yaml file
deploy:
	helm install consul hashicorp/consul --version $(CHART_VERSION) -f values.yaml

#### INSTALL ARGO
argo: deploy-argo apply-crds

deploy-argo:
	kubectl create namespace argo-rollouts; \
	kubectl apply -n argo-rollouts -f install.yaml
	kubectl apply -f $(PLUGIN_DIR)/yaml/rbac.yaml

apply-crds:
	kubectl apply -f resources/proxy-defaults.yaml \
	-f resources/serviceaccount.yaml \
	-f resources/service.yaml \
	-f resources/serviceaccount_client.yaml \
	-f resources/service_client.yaml \
	-f resources/deployment_client.yaml \
	-f resources/service-resolver.yaml \
	-f resources/service-splitter.yaml \
	-f resources/canary-rollout.yaml

### Test Verification
# Command for checking how the service is being split by running curl from inside a client pod
check-splitting:
	./scripts/test.sh

rollout-watch:
	kubectl argo rollouts get rollout static-server --watch

# Command used to deploy the canary deployment, will need to be promoted to continue
deploy-canary-v2:
	kubectl apply -f resources/canary_rollout_v2.yaml

# Command used to promote the canary deployment stopped with pause{}
promote:
	kubectl argo rollouts promote static-server

undo:
	kubectl argo rollouts undo static-server

abort:
	kubectl argo rollouts abort static-server

## EXTRAS
# Install argo rollouts kube extension
install-required-extensions:
	brew install argoproj/tap/kubectl-argo-rollouts; \
	brew install yq