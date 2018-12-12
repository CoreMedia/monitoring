
TYPE := cm-data-collector
IMAGE_NAME := docker-${TYPE}

BUILD_DATE      := $(shell date +%Y-%m-%d)
BUILD_VERSION   := $(shell date +%y%m)

.PHONY: build clean run shell exec stop

default: build

build:
	docker build \
		--rm \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg BUILD_VERSION=$(BUILD_VERSION) \
		--tag=$(IMAGE_NAME) .
	@echo Image tag: ${IMAGE_NAME}

run:
	docker run \
		--detach \
		--interactive \
		--tty \
		--name=${IMAGE_NAME} \
		$(IMAGE_NAME)

shell:
	docker run \
		--rm \
		--interactive \
		--tty \
		--hostname=${IMAGE_NAME} \
		--name=${IMAGE_NAME} \
		$(IMAGE_NAME) \
		sh

exec:
	docker exec \
		--interactive \
		--tty \
		${IMAGE_NAME} \
		/bin/sh

stop:
	docker kill \
		${IMAGE_NAME}

clean:
	did=$$(docker images -q ${IMAGE_NAME} | uniq); \
	if [ $$did ] ; then \
		docker rmi -f "$$did"; \
	fi
