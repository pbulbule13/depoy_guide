# #FROM python:3.10-slim
# FROM python:3.9.18-slim

# WORKDIR /app

# # Update pip first
# RUN pip install --upgrade pip

# RUN pip install --no-cache-dir faiss-cpu==1.7.4 spacy==3.7.2
# # Install system dependencies if needed
# RUN apt-get update && apt-get install -y \
#     gcc \
#     g++ \
#     && rm -rf /var/lib/apt/lists/*

# COPY requirements.txt .
# RUN pip install --no-cache-dir -r requirements.txt


# # Download spaCy model
# RUN python -m spacy download en_core_web_lg

FROM langchain/langchain:latest
COPY . /app
WORKDIR /app
RUN pip install streamlit python-dotenv
CMD ["streamlit", "run", "app.py"]


# Copy application code
COPY . .

# Create .streamlit directory and config
RUN mkdir -p .streamlit
RUN echo '[server]\nport = 8501\naddress = "0.0.0.0"\nheadless = true\n\n[browser]\ngatherUsageStats = false' > .streamlit/config.toml

# Expose port
EXPOSE 8501

# Health check and it is working 
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8501/_stcore/health || exit 1

# Run the application
CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0"]