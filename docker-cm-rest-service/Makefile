
export GIT_SHA1          := $(shell git rev-parse --short HEAD)
export DOCKER_IMAGE_NAME := rest-service
export DOCKER_NAME_SPACE := ${USER}
export DOCKER_TAG        ?= latest
export BUILD_DATE        := $(shell date +%Y-%m-%d)
export BUILD_VERSION     := $(shell date +%y%m)

.PHONY: build shell run exec start stop clean

default: build

build:
	@hooks/build

shell:
	@hooks/shell

run:
	@hooks/run

exec:
	@hooks/exec

start:
	@hooks/start

stop:
	@hooks/stop

clean:
	@hooks/clean

publish:
	@hooks/publish

linter:
	@tests/linter.sh

test: linter
