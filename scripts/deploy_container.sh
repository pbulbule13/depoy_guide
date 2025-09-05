name: Build and Deploy with Self-hosted Runner

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build-and-deploy:
    runs-on: self-hosted
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Debug Secrets (REMOVE AFTER FIXING)
      run: |
        echo "=== DEBUGGING SECRETS ==="
        echo "ECR_REPOSITORY length: ${#ECR_REPOSITORY}"
        echo "ECR_REPOSITORY value: '${ECR_REPOSITORY}'"
        echo "ECR_REPOSITORY (with quotes): \"${ECR_REPOSITORY}\""
        if [ -z "$ECR_REPOSITORY" ]; then
          echo "❌ ECR_REPOSITORY is EMPTY or NOT SET"
        else
          echo "✅ ECR_REPOSITORY is set"
        fi
        echo "========================"
      env:
        ECR_REPOSITORY: ${{ secrets.ECR_REPOSITORY }}
      
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-2
        
    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v2
      
    - name: Build, tag, and push image to Amazon ECR
      id: build-image
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        ECR_REPOSITORY: ${{ secrets.ECR_REPOSITORY }}
        IMAGE_TAG: ${{ github.sha }}
      run: |
        # Debug the variables before building
        echo "=== BUILD VARIABLES ==="
        echo "ECR_REGISTRY: $ECR_REGISTRY"
        echo "ECR_REPOSITORY: $ECR_REPOSITORY"
        echo "IMAGE_TAG: $IMAGE_TAG"
        echo "Full image name: $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"
        echo "======================="
        
        # Check if ECR_REPOSITORY is empty
        if [ -z "$ECR_REPOSITORY" ]; then
          echo "❌ ERROR: ECR_REPOSITORY is empty. Using fallback value."
          ECR_REPOSITORY="streamlit-app"
          echo "Using fallback: $ECR_REPOSITORY"
        fi
        
        # Build the docker image
        echo "Building Docker image..."
        docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
        docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:latest
        
        # Push the docker images
        echo "Pushing Docker images..."
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
        docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
        
    - name: Install Nginx
      run: |
        # Install Nginx if not installed
        if ! command -v nginx &> /dev/null; then
          echo "Installing Nginx..."
          sudo apt-get update
          sudo apt-get install -y nginx
        fi
        
        # Create directories if they don't exist
        sudo mkdir -p /etc/nginx/sites-available
        sudo mkdir -p /etc/nginx/sites-enabled
        
    - name: Deploy Container
      env:
        ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        ECR_REPOSITORY: ${{ secrets.ECR_REPOSITORY }}
        IMAGE_TAG: ${{ github.sha }}
      run: |
        # Use fallback if ECR_REPOSITORY is empty
        if [ -z "$ECR_REPOSITORY" ]; then
          ECR_REPOSITORY="streamlit-app"
        fi
        
        # Stop any existing container
        docker stop streamlit-container 2>/dev/null || true
        docker rm streamlit-container 2>/dev/null || true
        
        # Run the container
        docker run -d --name streamlit-container -p 8501:8501 --restart always $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
        
        # Configure Nginx
        echo "Creating Nginx configuration..."
        cat > /tmp/streamlit_nginx << 'EOL'
        server {
            listen 80;
            server_name _;
            
            location / {
                proxy_pass http://localhost:8501;
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_cache_bypass $http_upgrade;
                proxy_read_timeout 86400;
            }
        }
        EOL
        
        sudo cp /tmp/streamlit_nginx /etc/nginx/sites-available/streamlit
        sudo ln -sf /etc/nginx/sites-available/streamlit /etc/nginx/sites-enabled/
        sudo rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
        
        # Test nginx configuration before restarting
        sudo nginx -t
        sudo systemctl restart nginx
        sudo systemctl enable nginx 


#name: Build and Deploy with Self-hosted Runner
# on:
# push:
# branches: [ main ]
# jobs:
# build-and-deploy:
# runs-on: self-hosted
# steps:
# - name: Checkout code
# uses: actions/checkout@v2
# - name: Configure AWS credentials
# uses: aws-actions/configure-aws-credentials@v1
# with:
# aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
# aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
# aws-region: us-east-2
# - name: Login to Amazon ECR
# id: login-ecr
# uses: aws-actions/amazon-ecr-login@v1
# - name: Build, tag, and push image to Amazon ECR
# id: build-image
# env:
# ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
# ECR_REPOSITORY: ${{ secrets.ECR_REPOSITORY }}
# IMAGE_TAG: ${{ github.sha }}
# run: |
# # Build the docker image
# docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
# docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG $ECR_REGIST
# # Push the docker images
# docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
# docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
# - name: Install Nginx
# run: |
# # Install Nginx if not installed
# if ! command -v nginx &> /dev/null; then

# echo "Installing Nginx..."
# sudo apt-get update
# sudo apt-get install -y nginx
# fi
# # Create directories if they don't exist
# sudo mkdir -p /etc/nginx/sites-available
# sudo mkdir -p /etc/nginx/sites-enabled
# - name: Deploy Container
# env:
# ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
# ECR_REPOSITORY: ${{ secrets.ECR_REPOSITORY }}
# IMAGE_TAG: ${{ github.sha }}
# run: |
# # Stop any existing container
# docker stop streamlit-container 2>/dev/null || true
# docker rm streamlit-container 2>/dev/null || true
# # Run the container
# docker run -d --name streamlit-container -p 8501:8501 --restart always $EC
# # Configure Nginx
# echo "Creating Nginx configuration..."
# cat > /tmp/streamlit_nginx << 'EOL'
# server {
# listen 80;
# server_name _;
# location / {
# proxy_pass http://localhost:8501;
# proxy_http_version 1.1;
# proxy_set_header Upgrade $http_upgrade;
# proxy_set_header Connection "upgrade";
# proxy_set_header Host $host;
# proxy_cache_bypass $http_upgrade;
# proxy_read_timeout 86400;
# }
# }
# EOL
# sudo cp /tmp/streamlit_nginx /etc/nginx/sites-available/streamlit
# sudo ln -sf /etc/nginx/sites-available/streamlit /etc/nginx/sites-enabled/
# sudo rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
# sudo nginx -t
# sudo systemctl restart nginx

