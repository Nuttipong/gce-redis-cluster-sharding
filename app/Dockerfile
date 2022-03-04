FROM golang:1.14-alpine as build

RUN apk add --no-cache git

WORKDIR /src

COPY go.sum /src/
COPY go.mod /src/
COPY main.go /src/ 

RUN go build .

FROM alpine as runtime
WORKDIR /app
COPY --from=build /src/demo /app/demo
CMD [ "/app/demo" ]