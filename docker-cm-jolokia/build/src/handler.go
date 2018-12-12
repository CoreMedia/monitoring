package main

import (
  "fmt"
  "io"
  "io/ioutil"
  "net/http"
  "encoding/json"

  "github.com/gorilla/mux"
)

func Index(w http.ResponseWriter, r *http.Request) {

  fmt.Fprintln(w, "\n")
  fmt.Fprintln(w, " Welcome!")
  fmt.Fprintln(w, " this is a simple port scanner for CoreMedia Applications\n")
  fmt.Fprintln(w, " Try this:")
  fmt.Fprintln(w, "   curl -v -H \"Content-Type: application/json\" localhost:8088/scan/${HOSTNAME}")
  fmt.Fprintln(w, " or this")
  fmt.Fprintln(w, "   curl -v -H \"Content-Type: application/json\" localhost:8088/scan/${HOSTNAME} --data '{ \"ports\": [22,80,3306,999,55555] }' ")
  fmt.Fprintln(w, "\n\n")
}

func ScanHost(w http.ResponseWriter, r *http.Request) {

  var request Request

  vars := mux.Vars(r)
  host_name := vars["host"]

  body, err := ioutil.ReadAll(io.LimitReader(r.Body, 1048576))
  checkError(err)

  if err != nil {
    panic(err)
  }

  if err := r.Body.Close(); err != nil {
    checkError(err)
    panic(err)
  }

  if len( body ) != 0 {
    if err := json.Unmarshal(body, &request); err != nil {
      checkError(err)
    }
  }

  var ports []int

  if PingHost( host_name ) == true {
    ports = scan_port( host_name, request.Ports )
  }

  w.Header().Set("Content-Type", "application/json; charset=UTF-8")

  m := Message{ host_name, ports }

  if err := json.NewEncoder(w).Encode(m); err != nil {
    checkError(err)
    panic(err)
  }
}
