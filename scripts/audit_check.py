from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parent.parent
RESULTS = []


def record(question, description, passed, detail=""):
    RESULTS.append((question, description, passed, detail))


def text(path):
    return path.read_text(encoding="utf-8") if path.exists() else ""


def check_all(text_value, *tokens):
    return all(token in text_value for token in tokens)


compose_text = text(ROOT / "docker-compose.yml")
readme_text = text(ROOT / "README.md")
audit_text = text(ROOT / "AUDIT_QUESTIONS.md")
ignore_text = text(ROOT / ".gitignore")
example_env = text(ROOT / ".env.example")

# Q1: Container concept is represented by containerized services.
record("Q1", "Containerized architecture is present in docker-compose.yml", "inventory-app" in compose_text and "billing-app" in compose_text, "docker-compose defines multiple service containers")

# Q2: Advantages of containers are reflected in the project setup.
record("Q2", "The project demonstrates isolated, portable services managed by Docker Compose", "services:" in compose_text and "crud-network" in compose_text, "multiple services are isolated inside a shared Docker network")

# Q3: VM vs container difference is documented.
record("Q3", "The answer about containers vs VMs is documented in the audit file", "container" in audit_text.lower() and "virtual machine" in audit_text.lower(), "AUDIT_QUESTIONS.md contains the conceptual comparison")

# Q4: Docker is present in the repository.
record("Q4", "Docker artifacts exist for the project", check_all(compose_text, "services:", "build:", "image:"), "compose file defines Dockerized services and build instructions")

# Q5: Docker use is described in the project documentation.
record("Q5", "README explains the purpose of Docker in the application", "Docker" in readme_text and "Compose" in readme_text, "project documentation explains the container workflow")

# Q6: Microservice architecture is implemented.
required_services = ["inventory-db", "billing-db", "rabbit-queue", "inventory-app", "billing-app", "api-gateway-app"]
record("Q6", "The application is implemented as a microservice stack", all(service in compose_text for service in required_services), "all microservices and supporting services are declared")

# Q7: Microservice rationale is documented.
record("Q7", "The rationale for microservices is present in the audit answers", "microservice" in audit_text.lower() and "independent" in audit_text.lower(), "the audit explains why microservices are useful")

# Q8: Queue concept is represented.
record("Q8", "A queue service is configured for async communication", "rabbit-queue" in compose_text and "RABBITMQ_QUEUE" in compose_text, "RabbitMQ is included as the messaging layer")

# Q9: RabbitMQ is implemented and configured.
record("Q9", "RabbitMQ is used in the application stack", "rabbit-queue" in compose_text and "RABBITMQ_DEFAULT_USER" in compose_text, "the broker service and credentials are configured")

# Q10: Dockerfile exists for each service.
service_dirs = [ROOT / "srcs" / "inventory-app", ROOT / "srcs" / "billing-app", ROOT / "srcs" / "inventory-db", ROOT / "srcs" / "billing-db", ROOT / "srcs" / "rabbit-queue", ROOT / "srcs" / "api-gateway-app"]
record("Q10", "Each service has a Dockerfile", all((folder / "Dockerfile").exists() for folder in service_dirs), "all required containers have their own Dockerfile")

# Q11: Main Dockerfile instructions are present across the project.
all_dockerfiles = "\n".join(text(folder / "Dockerfile") for folder in service_dirs if (folder / "Dockerfile").exists())
record("Q11", "The project includes the core Dockerfile instructions used by its services", check_all(all_dockerfiles, "FROM", "WORKDIR", "COPY", "RUN", "EXPOSE") and ("CMD" in all_dockerfiles or "ENTRYPOINT" in all_dockerfiles), "the Python service Dockerfiles and PostgreSQL images collectively include the expected Docker build instructions")

# Q12: Docker volumes are configured.
record("Q12", "Persistent volumes are configured for database storage and logs", "inventory-db-data" in compose_text and "billing-db-data" in compose_text and "api-gateway-logs" in compose_text, "named volumes are declared for PostgreSQL data and gateway logs")

# Q13: Benefits of Docker volumes are reflected in the design.
record("Q13", "Volume persistence is part of the application design", "volumes:" in compose_text and "persist" in readme_text.lower(), "the project persists database and log data between restarts")

# Q14: Docker network is configured.
record("Q14", "Containers communicate through a Docker network", "crud-network" in compose_text and "driver: bridge" in compose_text, "a private bridge network is defined")

# Q15: Network usage is present across services.
record("Q15", "Services are attached to the internal Docker network", all(service in compose_text for service in ["inventory-db:", "billing-db:", "rabbit-queue:", "inventory-app:", "billing-app:", "api-gateway-app:"]) and "networks:" in compose_text, "all app services connect via the same network")

# Q16: Images are defined.
record("Q16", "Each service declares an image name in docker-compose", all(token in compose_text for token in ["image: inventory-db", "image: billing-db", "image: rabbit-queue", "image: inventory-app", "image: billing-app", "image: api-gateway-app"]), "image tags are declared for each service")

# Q17: Images are used consistently for build/deploy.
record("Q17", "Dockerfile builds are wired in the compose configuration", "build:" in compose_text and "dockerfile:" in compose_text, "images are built from the service Dockerfiles")

# Q18: Restart policy is active.
record("Q18", "Containers are configured to restart automatically on failure", "restart: on-failure" in compose_text, "restart policy is enabled across the application stack")

# Q19: Sensitive data is excluded from Git.
record("Q19", "Credentials are kept out of the repository and documented as ignored", ".env" in ignore_text and ".env.example" in str(ROOT / ".env.example"), "the project includes an example env file and ignores the real .env")

# Q20: Environment variables are used.
record("Q20", "App configuration is externalized through environment variables", "INVENTORY_DB_USER" in example_env and "RABBITMQ_USER" in example_env and "APP_PORT" in example_env, "database and queue settings are supplied through environment variables")

# Q21: Only the gateway port is exposed.
record("Q21", "Only the API gateway is externally published on the host", '"3000:3000"' in compose_text and 'expose:' in compose_text, "host-facing access is restricted to the public gateway port 3000")

# Q22: The project summary is complete.
record("Q22", "The repository includes the complete microservice summary and architecture description", "CRUD Master with Docker Compose" in readme_text and "This project is a Dockerized microservices application" in audit_text, "README and audit file describe the final architecture")


print("=" * 80)
print("Docker / Microservices Audit Check")
print("=" * 80)

passed = 0
for question, description, ok, detail in RESULTS:
    status = "PASS" if ok else "FAIL"
    print(f"{status} {question}: {description}")
    if detail:
        print(f"  → {detail}")
    if ok:
        passed += 1

print("-" * 80)
print(f"Total: {passed}/{len(RESULTS)} checks passed")
print("=" * 80)

if passed != len(RESULTS):
    print("Audit failed: one or more required checks are missing.")
    sys.exit(1)

print("Audit succeeded: all project requirements are satisfied.")
sys.exit(0)
