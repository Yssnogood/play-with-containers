# Audit Questions — Answers for the Docker / Microservices Project

## 1) What is a container?
Answer to question 1:
A container is a lightweight, portable execution environment that packages an application and its dependencies together. It runs in isolation from the host machine, but shares the host operating system kernel.

Benefits:
- portable and reproducible
- faster than virtual machines
- easier deployment
- consistent environment across machines

In this project, each service runs in its own container: inventory-app, billing-app, database, and RabbitMQ message broker.

## 2) What are the advantages of containers?
Answer to question 2:
- Consistency: the same app runs the same way everywhere
- Isolation: each service has its own environment
- Fast startup and deployment
- Better scaling and resource usage
- Easier management with Docker Compose
- Simplifies CI/CD and cloud deployment

## 3) What is the difference between a container and a virtual machine?
Answer to question 3:
A VM includes a full guest operating system and virtualization layer. A container shares the host OS kernel and runs only the app plus its libraries.

In short:
- VM = heavier, slower, more resource use
- Container = lighter, faster, more efficient

## 4) What is Docker?
Answer to question 4:
Docker is a platform used to build, ship, and run containers. It helps package applications with all their dependencies into images, then run them as containers.

Docker is useful because it standardizes development, testing, and production environments.

## 5) What is Docker used for?
Answer to question 5:
Docker is used to:
- run apps in isolated containers
- avoid "works on my machine" problems
- deploy microservices
- create consistent development environments
- manage databases and message brokers
- simplify deployment with Docker Compose

## 6) What is a microservice architecture?
Answer to question 6:
Microservice architecture is an approach where an application is split into small independent services, each responsible for one function.

Example in this project:
- inventory-app manages movies and stock
- billing-app processes orders and invoices
- api-gateway-app exposes the public API
- RabbitMQ transports messages between services
- PostgreSQL databases store each service's data

## 7) Why do we use microservices?
Answer to question 7:
- independent development and deployment
- better scaling of specific services
- team separation by function
- fault isolation
- easier maintenance than a single huge monolith

## 8) What is a queue?
Answer to question 8:
A queue is a data structure used to store messages waiting to be processed. It follows FIFO order: first in, first out.

A queue is useful to:
- decouple services
- avoid blocking the main app
- handle asynchronous processing
- improve resilience under load

## 9) What is RabbitMQ?
Answer to question 9:
RabbitMQ is an open-source message broker. It receives messages from producers and delivers them to consumers.

In this project, the API gateway sends billing requests to RabbitMQ, and the billing-app reads those messages to process the order.

## 10) What is a Dockerfile?
Answer to question 10:
A Dockerfile is a text file containing instructions used to build a Docker image.

Example instructions:
- FROM: base image to start from
- WORKDIR: working directory inside the container
- COPY: copy files into the image
- RUN: execute commands during build
- EXPOSE: document the port used by the application
- CMD: default command launched when the container starts

## 11) What are the main Dockerfile instructions?
Answer to question 11:
- FROM: chooses the base image
- WORKDIR: sets the working directory
- COPY: adds source code into the container
- RUN: installs dependencies or performs setup
- ENV: defines environment variables
- EXPOSE: exposes a port
- CMD: runs the app when the container starts

## 12) What is a Docker volume?
Answer to question 12:
A Docker volume is a persistent storage space managed by Docker. It keeps data even when the container is stopped or recreated.

In this project:
- PostgreSQL data is stored in volumes so the database data remains available
- logs can also be stored in a volume

## 13) Why do we use Docker volumes?
Answer to question 13:
- persist data beyond container lifetime
- avoid losing database content during rebuilds
- keep state for services like PostgreSQL
- easier backups and upgrades

## 14) What is a Docker network?
Answer to question 14:
A Docker network allows containers to communicate securely with each other using service names instead of localhost.

In this project, all services share the same internal bridge network called crud-network.

## 15) Why do we use a Docker network?
Answer to question 15:
- containers can discover each other by hostname
- isolated internal communication
- no need to expose every service publicly
- cleaner architecture and less configuration error

## 16) What is a Docker image?
Answer to question 16:
A Docker image is a read-only template created from a Dockerfile. It contains the application code and all dependencies needed to run it.

Each container is created from an image.

## 17) Why do we use Docker images?
Answer to question 17:
- standardize deployment
- reuse the same environment in dev and production
- versioned, reproducible builds
- easy rollout with Docker Compose

## 18) Why is restart: on-failure important?
Answer to question 18:
This ensures that if a container crashes because of an error, Docker will automatically restart it. This improves service availability and reduces manual intervention.

In this project, all services use restart: on-failure.

## 19) Why should sensitive data not be pushed to Git?
Answer to question 19:
Because credentials and connection details should stay private. Putting them in Git exposes password, database credentials, and tokens, which is a security risk.

This is why the .env file is ignored and not committed.

## 20) Why do we use environment variables?
Answer to question 20:
Environment variables allow configuration to change without modifying code. They are commonly used for:
- database connection settings
- app ports
- credentials
- service URLs
- queue settings

This makes the project more portable and secure.

## 21) Why do we expose only the gateway port?
Answer to question 21:
The gateway is the public entry point. Internal services should remain private inside the Docker network. This reduces attack surface and keeps internal communication isolated.

In this project, only the API gateway exposes port 3000 to the host machine.

## 22) Summary of this project
Answer to question 22:
This project is a Dockerized microservices application:
- API gateway exposes HTTP endpoints
- Inventory service handles movie and inventory data
- Billing service handles payment/order processing
- PostgreSQL stores each service's data
- RabbitMQ carries asynchronous billing messages
- Docker Compose orchestrates the whole stack
- Docker volumes persist data
- Docker network is used for internal service communication
- restart: on-failure ensures better uptime

This is a good example of a small but realistic microservices architecture.
