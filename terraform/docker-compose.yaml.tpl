version: '3.7'
services:
  catgpt:
    container_name: catgpt
    image: ${ app-image-tag }
    restart: always
    network_mode: "host"
