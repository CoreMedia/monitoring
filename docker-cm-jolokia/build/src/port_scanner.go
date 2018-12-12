package main

import (
  "fmt"
  "net"
  "os"
)

func scan_port(host string, ports_optional []int) []int {

  array := []int{ 80, 443, 3306, 5432, 6379, 8081, 9100, 19100, 27017, 38099,
        40099,
        40199,
        40299,
        40399,
        40499,
        40599,
        40699,
        40799,
        40899,
        40999,
        41099,
        41199,
        41299,
        41399,
        42099,
        42199,
        42299,
        42399,
        42499,
        42599,
        42699,
        42799,
        42899,
        42999,
        43099,
        44099,
        45099,
        46099,
        47099,
        48099,
        49099,
        55555 }

  if len(ports_optional) != 0 {
    array = ports_optional
  }

  var open_ports []int

  for _,element := range array {

    if IsOpen( host, element ) == true {
      open_ports = append(open_ports, element)
    }
  }

  return open_ports
}

func printSlice(s []int) {
  fmt.Printf("len=%d cap=%d %v\n", len(s), cap(s), s)
}


func IsOpen(host string, port int) bool {

  tcpAddr, err := net.ResolveTCPAddr("tcp4", fmt.Sprintf("%s:%d", host,port ) )
//   checkError(err)

  if err != nil {
//    fmt.Println( "ERROR can not resolve ", host )
    return false
  }

  conn, err := net.DialTCP("tcp", nil, tcpAddr)
//   checkError(err)

  if err != nil {
//    fmt.Println( "ERROR port not open" )
    return false
  }

  defer conn.Close()

  return true
}

func checkError(err error) {
  if err != nil {
    fmt.Fprintf(os.Stderr, "Fatal error: %s\n", err.Error())
  }
}


