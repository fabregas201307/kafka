RELEASE_NAME=fiqr-kafka-cluster
IMAGE_NAME=ACRFIQUANTITPROD001.AZURECR.IO/${RELEASE_NAME}
SHA:=$(if $(SHA),$(SHA),$(shell git rev-parse --short HEAD))
REPO_NAME=$(shell git config --get remote.origin.url | sed 's/.*\/\([^ ]*\/[^.]*\).*/\1/' | sed -e "s/\//-/g")
BRANCH_NAME=$(shell git rev-parse --abbrev-ref HEAD)

FULL_IMAGE_TAG_RAW:=$(IMAGE_NAME):${REPO_NAME}-${BRANCH_NAME}-gc-${SHA}
FULL_IMAGE_TAG:=$(shell echo $(FULL_IMAGE_TAG_RAW) | tr A-Z a-z)

OVERWRITE_IMAGE_TAG:=$(IMAGE_NAME):latest
SCAN_IMAGE_TAG:=$(RELEASE_NAME):latest
BUILD_ENV:=$(if $(BUILD_ENV),$(BUILD_ENV),dev)

CLUSTER_NAME=aks-cortex-prod-003
CLUSTER_NAMESPACE=fiquantit-prod
DEPLOYMENT_SERVICE_NAME=fiqr-kafka-cluster

.PHONY: build test push deploy_aks clean

build:
	$(info FULL_IMAGE_TAG=${FULL_IMAGE_TAG}...)
	$(info $(shell git log --oneline | tac | tail -1))
	docker build -t '${FULL_IMAGE_TAG}' -f docker/Dockerfile . --no-cache
	docker tag '${FULL_IMAGE_TAG}' '${OVERWRITE_IMAGE_TAG}'
	docker tag '${FULL_IMAGE_TAG}' '${SCAN_IMAGE_TAG}'

test:
	docker run -i --entrypoint sh '${FULL_IMAGE_TAG}' -c "\
		/usr/bin/start-kafka.sh & \
		sleep 30 && \
		nc -z localhost 9092 && \
		nc -z localhost 2181"

push:
	docker push '${FULL_IMAGE_TAG}'
	docker push '${OVERWRITE_IMAGE_TAG}'

deploy_aks:
	@echo "Deploying Kafka to AKS..."
	whoami
	kubectl --context="${CLUSTER_NAME}" delete service ${DEPLOYMENT_SERVICE_NAME} -n ${CLUSTER_NAMESPACE} || true
	kubectl --context="${CLUSTER_NAME}" delete statefulset ${DEPLOYMENT_SERVICE_NAME} -n ${CLUSTER_NAMESPACE} || true
	kubectl --context="${CLUSTER_NAME}" delete configmap ${DEPLOYMENT_SERVICE_NAME}-config -n ${CLUSTER_NAMESPACE} || true
	kubectl --context="${CLUSTER_NAME}" -n ${CLUSTER_NAMESPACE} apply -f ./deploy/values.yaml

clean:
	docker rmi '${FULL_IMAGE_TAG}' || true
	docker rmi '${OVERWRITE_IMAGE_TAG}' || true
	docker rmi '${SCAN_IMAGE_TAG}' || true

# Development helpers
dev:
	docker-compose up -d

dev_down:
	docker-compose down

logs:
	kubectl --context="${CLUSTER_NAME}" logs -f statefulset/${DEPLOYMENT_SERVICE_NAME} -n ${CLUSTER_NAMESPACE}

status:
	kubectl --context="${CLUSTER_NAME}" get all -n ${CLUSTER_NAMESPACE} -l app=${DEPLOYMENT_SERVICE_NAME}

# Additional helper targets
create_topics:
	kubectl --context="${CLUSTER_NAME}" exec -it ${DEPLOYMENT_SERVICE_NAME}-0 -n ${CLUSTER_NAMESPACE} -- \
		kafka-topics.sh --create --bootstrap-server localhost:9092 \
		--replication-factor 3 --partitions 3 --topic test-topic

list_topics:
	kubectl --context="${CLUSTER_NAME}" exec -it ${DEPLOYMENT_SERVICE_NAME}-0 -n ${CLUSTER_NAMESPACE} -- \
		kafka-topics.sh --list --bootstrap-server localhost:9092

help:
	@echo "Available commands:"
	@echo "  make build         - Build Docker image"
	@echo "  make test          - Run tests"
	@echo "  make push          - Push Docker image to ACR"
	@echo "  make deploy_aks    - Deploy to AKS"
	@echo "  make clean         - Clean up Docker images"
	@echo "  make dev           - Start local development environment"
	@echo "  make dev_down      - Stop local development environment"
	@echo "  make logs          - View logs in AKS"
	@echo "  make status        - Check deployment status"
	@echo "  make create_topics - Create test topics"
	@echo "  make list_topics   - List all topics"