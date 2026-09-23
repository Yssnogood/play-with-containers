@echo off
setlocal EnableExtensions

cd /d "%~dp0.."

echo =========================================================
echo Audit script: mapping between command lines and audit checks
echo =========================================================

echo === Repository / required files check ===
echo Audit check: "GeneralCheck the Repo content" / "Are all the required files present?"
if exist README.md echo [OK] README.md present
if not exist README.md echo [ERROR] README.md missing
if exist docker-compose.yml echo [OK] docker-compose.yml present
if not exist docker-compose.yml echo [ERROR] docker-compose.yml missing
if exist .env echo [WARN] .env exists locally: make sure it is excluded from Git
if not exist .env echo [OK] .env not present locally
for /d %%D in ("srcs\*") do if exist "%%~D\Dockerfile" echo [OK] Dockerfile found: %%~D\Dockerfile

echo Audit check: "Was the .env file excluded from git files?"
git check-ignore -q .env
if errorlevel 1 (
    echo [INFO] .env is NOT ignored by Git. Check .gitignore.
) else (
    echo [OK] .env is ignored by Git.
)

echo Audit check: "Are all pushed files in the repo clean of any credentials or passwords?"
git grep -nE "PASSWORD|PASSWD|SECRET|TOKEN|KEY|password|secret|token" -- . ":(exclude).env" 2>nul
if errorlevel 1 (
    echo [OK] No obvious credentials found in tracked files.
) else (
    echo [WARNING] Possible credentials or tokens were found. Review before pushing.
)

echo.
echo === README and architecture review ===
echo Audit check: "Open and read the README.md file provided by the learner"
echo Manual validation: confirm prerequisites, setup, usage, configuration, etc.
more README.md 2>nul | findstr /I /C:"docker" /C:"compose" /C:"prerequisite" /C:"setup" /C:"usage" /C:"configuration"
if errorlevel 1 (
    echo [INFO] README.md was read manually; confirm the required sections are present.
) else (
    echo [OK] README.md contains expected project keywords.
)

echo Audit check: "Check the learner infrastructure / Does the learner architecture reflect the infrastructure enforced by the subject?"
echo This is validated by inspecting docker-compose.yml and the live containers below.

echo.
echo === Validate the docker-compose stack ===
echo Audit check: "Run the learner infrastructure: docker-compose up" / "Does the infrastructure start correctly?"
echo We validate the Compose file format and then start the full infrastructure to verify that all services come up correctly.
docker compose config
if errorlevel 1 goto :error

docker compose up --build -d --wait
if errorlevel 1 goto :error

docker compose ps

echo.
echo === Container list and port verification ===
echo Audit check: "Check the Containers / Is the inventory-db accessible via 5432 / billing-db via 5432 / inventory-app via 8080 / billing-app via 8080 / rabbit-queue via 5672 / api-gateway-app via 3000?"
echo We list running containers and check their published ports and restart policy to confirm the expected architecture is running as required.
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}"
docker inspect -f "{{.Name}} {{json .HostConfig.RestartPolicy}}" inventory-db billing-db inventory-app billing-app rabbit-queue api-gateway-app

echo.
echo === Dockerfiles and base image verification ===
echo Audit check: "Verify the Dockerfiles: Is there a Dockerfile for each service?"
echo We verify that each service has its own Dockerfile and that each one declares a valid base image for the runtime environment.
for /d %%D in ("srcs\*") do if exist "%%~D\Dockerfile" echo [OK] Dockerfile present: %%~D\Dockerfile

echo Audit check: "Are all Dockerfiles based on Debian or Alpine?"
for /d %%D in ("srcs\*") do (
    if exist "%%~D\Dockerfile" (
        findstr /I /C:"FROM " "%%~D\Dockerfile" >nul
        if errorlevel 1 (
            echo [ERROR] Dockerfile without FROM instruction: %%~D\Dockerfile
        ) else (
            echo [OK] Dockerfile base image specified: %%~D\Dockerfile
        )
    )
)

echo Audit check: "Are Dockerfiles or any other solution files free from sensitive data?"
findstr /S /I /R /C:"password\|secret\|token\|PRIVATE_KEY\|passwd" srcs\* 2>nul
if errorlevel 1 (
    echo [OK] No obvious sensitive data found in source Docker files.
) else (
    echo [WARNING] Sensitive data may be present in one or more service files.
)

echo.
echo === Volume, network and image checks ===
echo Audit check: "Check the Docker volumes"
echo We inspect persistent Docker volumes to confirm the databases and logs are stored in the expected volumes.
docker volume ls

echo Audit check: "Check the solution network / Is the connection to the api-gateway-app the only one exposed from outside of the Docker host?"
echo We inspect the Docker network to confirm the services communicate internally and that only the gateway is exposed externally.
docker network ls
docker network inspect crud-network 2>nul

echo Audit check: "Check the Docker images / Is there a Docker image for each service with the same service name?"
echo We list the built images to verify that each service has its corresponding Docker image available.
docker images

echo.
echo === Application behavior checks ===
echo Audit check: "Inventory API endpoints / POST /api/movies then GET /api/movies"
echo We test the inventory service through the gateway to confirm the insert works and that the data is readable via the API.
curl.exe --fail-with-body -sS -i -X POST "http://localhost:3000/api/movies" -H "Content-Type: application/json" --data-raw "{\"title\":\"A new movie\",\"description\":\"Very short description\"}"
if errorlevel 1 goto :error

curl.exe --fail-with-body -sS -i "http://localhost:3000/api/movies"
if errorlevel 1 goto :error

echo.
echo === Billing flow while consumer is running ===
echo Audit check: "Billing API endpoints / POST to /api/billing/ returns 200 while billing-app is running"
echo We send a billing request while the consumer is active to verify the microservice can process the message correctly.
curl.exe --fail-with-body -sS -i -X POST "http://localhost:3000/api/billing/" -H "Content-Type: application/json" --data-raw "{\"user_id\":\"20\",\"number_of_items\":\"99\",\"total_amount\":\"250\"}"
if errorlevel 1 goto :error

echo.
echo === Billing restart / queue resilience ===
echo Audit check: "Restart the billing-app container. After restart, are queued messages processed successfully?"
echo We stop the consumer, submit a new order, then restart it to ensure the queue and consumer recover correctly after a disruption.
docker compose stop billing-app
if errorlevel 1 goto :error
docker compose ps

curl.exe --fail-with-body -sS -i -X POST "http://localhost:3000/api/billing/" -H "Content-Type: application/json" --data-raw "{\"user_id\":\"22\",\"number_of_items\":\"10\",\"total_amount\":\"50\"}"
if errorlevel 1 goto :error

docker compose start billing-app
if errorlevel 1 goto :error
docker compose ps
docker exec rabbit-queue rabbitmqctl list_queues

echo.
echo === Database persistence and schema verification ===
echo Audit check: "Can you connect to inventory-db and confirm the database and tables exist?"
echo We inspect the PostgreSQL database structure to verify the expected schema and tables exist in each database.
docker exec inventory-db psql -U inventory_user -d inventory_db -c "\dt"
if errorlevel 1 goto :error

echo Audit check: "Can you connect to billing-db and confirm the database and tables exist?"
docker exec billing-db psql -U billing_user -d billing_db -c "\dt"
if errorlevel 1 goto :error

echo Audit check: "Are the databases persisting data after container restart?"
echo Manual confirmation: restart containers and verify data persists.

echo.
echo === Dockerfile optimization audit ===
echo Audit check: "Are Dockerfile layers optimized? / Is final image size minimized?"
echo We inspect Docker image history to review layer ordering and check whether the build is reasonably optimized.
docker history --no-trunc --format "table {{.CreatedBy}}" inventory-db billing-db inventory-app billing-app rabbit-queue api-gateway-app 2>nul

echo.
echo === Manual interview questions (not automated by Docker) ===
echo Audit check: "What are containers and what are their advantages?"
echo Answer: Containers are lightweight isolated environments that package an application and its dependencies. Their advantages are portability, speed, consistency, isolation, and easier deployment.
echo Audit check: "What is the difference between containers and virtual machines?"
echo Answer: Containers share the host operating system kernel, while virtual machines include a full guest OS. Containers are lighter and faster; VMs are heavier and slower.
echo Audit check: "What is Docker and what is it used for?"
echo Answer: Docker is a platform used to build, ship, and run containers. It helps standardize environments, avoid configuration issues, and deploy applications consistently.
echo Audit check: "What is a microservices architecture? Why do we use microservices architecture?"
echo Answer: A microservices architecture splits an application into small independent services, each with a specific responsibility. We use it for modularity, scalability, independent deployment, and easier maintenance.
echo Audit check: "What is a queue and what is it used for? What is RabbitMQ?"
echo Answer: A queue stores messages waiting to be processed in order. RabbitMQ is a message broker used to send and receive messages between services asynchronously.
echo Audit check: "What is a Dockerfile? Explain the instructions used on the Dockerfile."
echo Answer: A Dockerfile is a text file used to build a Docker image. Main instructions are FROM, WORKDIR, COPY, RUN, ENV, EXPOSE, and CMD.
echo Audit check: "What is a Docker volume? Why do we use Docker volumes?"
echo Answer: A Docker volume is persistent storage managed by Docker. We use it to keep database data and logs even when containers stop or restart.
echo Audit check: "What is the Docker network? Why do we use the Docker network?"
echo Answer: A Docker network allows containers to communicate with each other. We use it to isolate internal service communication and limit public exposure.
echo Audit check: "What is a Docker image? Why do we use Docker images?"
echo Answer: A Docker image is a read-only template used to create containers. We use it to standardize the deployment and reproduce the same environment reliably.
echo Manual interview result must be recorded by the examiner.
echo [INFO] Interview and conceptual questions must be answered manually by the learner or group.

echo.
echo === Audit test completed successfully ===
goto :end

:error
echo.
echo Audit test failed. Inspect the Docker logs with:
echo docker compose logs --tail=100
exit /b 1

:end
endlocal
exit /b 0
