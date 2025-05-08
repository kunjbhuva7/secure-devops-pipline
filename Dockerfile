# Use openjdk:11-slim as the base image (includes Java)
FROM openjdk:11-slim

# Install Python and required dependencies (pip, unzip, wget)
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-dev \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install SonarScanner
RUN wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip && \
    unzip sonar-scanner-cli-5.0.1.3006-linux.zip -d /opt/ && \
    ln -s /opt/sonar-scanner-5.0.1.3006-linux /opt/sonar-scanner && \
    echo 'export PATH=$PATH:/opt/sonar-scanner/bin' >> ~/.bashrc

# Set the working directory for the app
WORKDIR /app

# Copy the requirements file and install Python dependencies
COPY requirements.txt requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy the rest of the application files
COPY . .

# Expose the required port (Flask app default port)
EXPOSE 5000

# Set environment variable for Flask to run in production (optional)
ENV FLASK_ENV=production

# Default command to run your app
CMD ["python3", "app.py"]

