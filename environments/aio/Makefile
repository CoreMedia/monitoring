
CURRENT_DIRECTORY := $(shell pwd)

.PHONY: build up start stop status restart clean down pull build tail

# help:
# 	@echo "Docker Compose Help"
# 	@echo "-----------------------"
# 	@echo ""
# 	@echo "start th complete stack:"
# 	@echo "    make start"
# 	@echo ""
# 	@echo "Really, really start over:"
# 	@echo "    make clean"
# 	@echo ""
# 	@echo "See contents of Makefile for more targets."

default: build

up:
	@docker-compose up --build

start:
	@docker-compose up --build -d

stop:
	@docker-compose stop

status:
	@docker-compose ps

restart: stop start


clean: stop
	@docker-compose rm --force

kill:
	@docker-compose kill

down:
	@docker-compose down

pull:
	@docker-compose pull

build:
	@docker-compose build

tail:
	@docker-compose logs -f
