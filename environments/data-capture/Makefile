CURRENT_DIRECTORY := $(shell pwd)

help:
	@echo "Docker Compose Help"
	@echo "-----------------------"
	@echo ""
	@echo "start th complete stack:"
	@echo "    make begin"
	@echo ""
	@echo "Really, really start over:"
	@echo "    make clean"
	@echo ""
	@echo "See contents of Makefile for more targets."

begin: pull start

start:
	@docker-compose up --build -d

stop:
	@docker-compose stop

status:
	@docker-compose ps

restart: stop start


clean: stop
	@docker-compose rm --force

down:
	@docker-compose down

pull:
	@docker-compose pull

build:
	@docker-compose build

tail:
	@docker-compose logs -f

.PHONY: start stop status restart clean build down tail
