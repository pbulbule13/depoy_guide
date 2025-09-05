# # # Use slim Python image to save space
# # FROM python:3.9-slim

# # # Set working directory
# # WORKDIR /app

# # # Install system dependencies (minimal)
# # RUN apt-get update && apt-get install -y --no-install-recommends \
# #     gcc \
# #     && rm -rf /var/lib/apt/lists/* \
# #     && apt-get clean

# # # Copy only requirements first (for better caching)
# # COPY requirements.txt .

# # # Install Python packages with cleanup
# # RUN pip install --no-cache-dir -r requirements.txt \
# #     && pip cache purge

# # # Copy application code
# # COPY . .
# # # Expose port
# # EXPOSE 8501

# # # Health check and it is working fine
# # HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
# #     CMD curl -f http://localhost:8501/_stcore/health || exit 1

# # # Run the application
# # CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0"]

# FROM python:3.9-slim

# WORKDIR /app

# # Install packages individually without dependency checking
# RUN pip install --no-cache-dir --upgrade pip

# # Install core packages first
# RUN pip install --no-cache-dir --no-deps langchain-core==0.1.52
# RUN pip install --no-cache-dir --no-deps langchain-community==0.0.38
# RUN pip install --no-cache-dir --no-deps langchain==0.1.17
# RUN pip install --no-cache-dir --no-deps langchain-openai==0.1.3
# RUN pip install --no-cache-dir --no-deps langchain-text-splitters==0.0.1

# # Install other packages normally
# RUN pip install --no-cache-dir pydantic==2.5.3 openai==1.6.1 streamlit==1.28.1 python-dotenv==1.0.0

# COPY . .

# EXPOSE 8501

# CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0"]

FROM langchain/langchain:latest

WORKDIR /app

RUN pip install streamlit python-dotenv PyPDF2 faiss-cpu spacy

# Only install what's missing
RUN pip install streamlit python-dotenv

COPY . .

EXPOSE 8501

CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0"]