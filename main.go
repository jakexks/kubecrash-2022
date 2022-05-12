package main

import (
	"bytes"
	"crypto/tls"
	"fmt"
	"net/http"
	"os"
	"strings"
)

func main() {
	hasTLS := true
	_, err := os.ReadFile("/tls/tls.crt")
	if err != nil {
		hasTLS = false
	}
	_, err = os.ReadFile("/tls/tls.key")
	if err != nil {
		hasTLS = false
	}
	http.HandleFunc("/", handler)
	if hasTLS {
		cert, err := tls.LoadX509KeyPair("/tls/tls.crt", "/tls/tls.key")
		if err != nil {
			fmt.Fprintf(os.Stderr, "couldn't load tls keypair (%s)\n", err.Error())
			os.Exit(1)
		}
		config := &tls.Config{
			Certificates: []tls.Certificate{cert},
			ClientAuth:   tls.RequireAndVerifyClientCert,
		}
		l, err := tls.Listen("tcp", ":8080", config)
		if err != nil {
			fmt.Fprintf(os.Stderr, "couldn't listen on :8080 (%s)\n", err.Error())
			os.Exit(1)
		}
		defer l.Close()

		if err := http.Serve(l, nil); err != nil {
			fmt.Fprintf(os.Stderr, "%s\n", err.Error())
			os.Exit(1)
		}
	} else {
		if err := http.ListenAndServe(":8080", nil); err != nil {
			fmt.Fprintf(os.Stderr, "%s\n", err.Error())
			os.Exit(1)
		}
	}
}

var preamble = `<!DOCTYPE html>
<html>
<head>
<title>Super Secure company app</title>
</head>
<body>
`
var postamble = `</body>

</html>
`

func handler(w http.ResponseWriter, r *http.Request) {
	resp := &bytes.Buffer{}
	resp.WriteString(preamble)

	email := r.Header.Get("X-Forwarded-Email")
	if email == "admin@jetstack.io" {
		resp.WriteString("<h1 style=\"color: red\">You are an admin and can do scary things!</h1>")
	} else {
		resp.WriteString("<h1>Welcome, " + email + "</h1>")
	}

	resp.WriteString("<p>You sent headers:</p><pre>")
	for k, v := range r.Header {
		resp.WriteString(k + ": ")
		resp.WriteString(strings.Join(v, ", ") + "\n")
	}
	resp.WriteString("</pre>")
	resp.WriteString(postamble)
	w.Write(resp.Bytes())
}
