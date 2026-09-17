package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"runtime"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		host, _ := os.Hostname()
		fmt.Fprintf(w, "hello from the multi-stage build\n")
		fmt.Fprintf(w, "host: %s\n", host)
		fmt.Fprintf(w, "go:   %s\n", runtime.Version())
		fmt.Fprintf(w, "arch: %s/%s\n", runtime.GOOS, runtime.GOARCH)
	})
	http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "ok")
	})
	log.Println("listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
