# Use a lightweight Python base image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy app files
COPY . /app

# Install dependencies
RUN pip install --no-cache-dir flask

# Expose port 5000
EXPOSE 5000

# Run the app
CMD ["python", "app.py"]