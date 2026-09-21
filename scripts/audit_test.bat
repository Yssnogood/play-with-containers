@echo off
setlocal

cd /d "%~dp0.."

echo === Validate and start Docker Compose ===
docker compose config
if errorlevel 1 goto :error

docker compose up --build -d --wait
if errorlevel 1 goto :error

docker compose ps

echo.
echo === Check ports and restart policies ===
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}"
docker inspect -f "{{.Name}} {{json .HostConfig.RestartPolicy}}" inventory-db billing-db inventory-app billing-app rabbit-queue api-gateway-app

echo.
echo === Test inventory POST ===
curl.exe --fail-with-body -sS -i -X POST "http://localhost:3000/api/movies" -H "Content-Type: application/json" --data-raw "{\"title\":\"A new movie\",\"description\":\"Very short description\"}"
if errorlevel 1 goto :error

echo.
echo === Test inventory GET ===
curl.exe --fail-with-body -sS -i "http://localhost:3000/api/movies"
if errorlevel 1 goto :error

echo.
echo === Inventory GET check passed ===

echo.
echo === Test billing while consumer is running ===
curl.exe --fail-with-body -sS -i -X POST "http://localhost:3000/api/billing/" -H "Content-Type: application/json" --data-raw "{\"user_id\":\"20\",\"number_of_items\":\"99\",\"total_amount\":\"250\"}"
if errorlevel 1 goto :error

echo.
echo === Stop billing consumer ===
docker compose stop billing-app
if errorlevel 1 goto :error
docker compose ps

echo.
echo === Test billing while consumer is stopped ===
curl.exe --fail-with-body -sS -i -X POST "http://localhost:3000/api/billing/" -H "Content-Type: application/json" --data-raw "{\"user_id\":\"22\",\"number_of_items\":\"10\",\"total_amount\":\"50\"}"
if errorlevel 1 goto :error

echo.
echo === Restart billing consumer and inspect queue ===
docker compose start billing-app
if errorlevel 1 goto :error
docker compose ps
docker exec rabbit-queue rabbitmqctl list_queues

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
