# Build the application from source
FROM golang:1.21 AS build

WORKDIR /src/catgpt

COPY ./ ./
RUN go mod download
RUN CGO_ENABLED=0 go build -o /bin/catgpt

# Run the tests in the container
FROM build AS test
RUN go test -v ./...

# Deploy the application binary into a lean image
FROM gcr.io/distroless/static-debian12:latest-amd64 AS release

WORKDIR /

COPY --from=build /bin/catgpt /catgpt

EXPOSE 8080

USER nonroot:nonroot

ENTRYPOINT ["/catgpt"]
