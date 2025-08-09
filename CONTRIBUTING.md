# How to Contribute

Thank you for your interest in contributing to the project! To ensure code quality and consistency, please follow the guidelines below.

## Testing Infrastructure Changes Locally

To ensure that changes to the `Dockerfile`, `docker-compose.*.yml`, or other infrastructure configuration files do not break the environment, we have created a script to simulate the production stack locally.

**Purpose:** To validate the Docker image build process and the interaction between services (app, nginx, mysql) exactly as configured for production.

### Prerequisites
* Docker and Docker Compose installed.
* An `.env` file in the project root (you can copy it from `.env.example` and fill in the variables, especially the `DB_*` ones).

### Step-by-Step
1.  **Grant execute permission to the `local.sh` script**. You only need to do this once after cloning the repository.
    ```bash
    chmod +x local.sh
    ```
2.  To build, start, and initialize the entire environment, run a single command in your terminal:
    ```bash
    ./local.sh
    ```
3.  The script will:
    * Stop and remove any old containers. 
    * Build the Docker image from scratch. 
    * Start all services. 
    * Wait for the database to be ready. 
    * Run the Laravel migrations.
4.  After completion, the application will be accessible at **`http://localhost`**.

### Shutting Down the Environment
To stop and remove the containers and volumes, use the following command:
```bash
docker compose -f docker-compose.prod.yml -f docker-compose.local.prod.yml down -v
```
