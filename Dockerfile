FROM docker.io/library/golang:1.18.1 as builder
ENV CGO_ENABLED=0
RUN mkdir -p /app
COPY go.mod main.go /app/
WORKDIR /app
RUN go build -v
FROM alpine
COPY --from=builder /app/kubecrash-2022 /kubecrash-2022
ENTRYPOINT [ "/kubecrash-2022" ]
