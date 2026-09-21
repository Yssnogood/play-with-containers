# CRUD Master with Docker Compose

This project packages the CRUD microservices into a Docker Compose environment with separate containers for the inventory service, billing service, PostgreSQL databases, RabbitMQ, and the API gateway.

## Architecture

The application is composed of the following services:

- `inventory-db`: PostgreSQL database for inventory data
- `billing-db`: PostgreSQL database for billing data
- `inventory-app`: Flask API that manages movies
- `billing-app`: Flask service that consumes orders from RabbitMQ and stores them in the billing database
- `rabbit-queue`: RabbitMQ broker used for asynchronous billing messages
- `api-gateway-app`: public entry point for the application on port `3000`

All services are connected through a private Docker network, while only the API gateway is exposed to the host machine.

## Prerequisites

Before running the project, install:

- Docker
- Docker Compose

## Environment configuration

Copy the example environment file and adjust the credentials if needed:

```bash
cp .env.example .env
```

The `.env` file is ignored by Git and contains the credentials used by PostgreSQL and RabbitMQ.

## Build and run

From the project root, start the whole stack:

```bash
docker compose up --build -d
```

To inspect logs:

```bash
docker compose logs -f
```

To stop the stack:

```bash
docker compose down -v
```

## Service access

Once the stack is running:

- API Gateway: `http://localhost:3000`
- Inventory API: `http://inventory-app:8080`
- Billing API: `http://billing-app:8080`
- Inventory database: `inventory-db:5432`
- Billing database: `billing-db:5432`
- RabbitMQ: `rabbit-queue:5672`

## Example requests

Create a movie through the gateway:

```bash
curl -X POST http://localhost:3000/api/movies \
  -H "Content-Type: application/json" \
  -d '{"title":"movie","description":"wonderful plot"}'
```

List movies:

```bash
curl http://localhost:3000/api/movies
```

## Notes

- The container images for the Python services are built from the project source using dedicated Dockerfiles.
- Named volumes ensure that PostgreSQL data and gateway logs persist between container restarts.
- The services restart automatically unless the containers are explicitly stopped.
- The Docker Compose configuration uses service names instead of `localhost` so the apps can communicate correctly inside the internal network.
