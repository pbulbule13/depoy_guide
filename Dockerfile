# Use slim Python image to save space
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install system dependencies (minimal)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy only requirements first (for better caching)
COPY requirements.txt .

# Install Python packages with cleanup
RUN pip install --no-cache-dir -r requirements.txt \
    && pip cache purge

# Copy application code
COPY . .
# Expose port
EXPOSE 8501

# Health check and it is working fine
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8501/_stcore/health || exit 1

# Run the application
CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0"]