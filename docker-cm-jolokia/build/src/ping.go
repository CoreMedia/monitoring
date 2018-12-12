package main

import (
  "log"
  "os/exec"
  "strings"
)

func PingHost(host string) (bool) {

  cmd := exec.Command("ping", host, "-4", "-c1", "-w1", "-W1")

  output, err := cmd.CombinedOutput()

  if err != nil {
    log.Printf("event='ping_cmd_error' name='%s' error='%s'\n", host, err)
  }

  if strings.Contains(string(output), "Destination Host Unreachable") {
    return false
  } else {
    return true
  }
}
