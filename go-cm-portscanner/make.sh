#!/bin/bash

export GOPATH=${PWD}
cd src

go get github.com/gorilla/mux
go build -ldflags="-s -w" -o service-discovery

