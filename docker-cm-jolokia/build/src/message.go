package main

type Message struct {
  Host string `json:"host"`
  Ports []int  `json:"ports"`
}

type Request struct {
  Ports []int `json:"ports"`
}
