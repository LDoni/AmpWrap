# AmpWrap Dockerfile (HPC-friendly, reproducible using locked environment)
FROM mambaorg/micromamba:1.5.8

# Set working directory inside the container
WORKDIR /opt/ampwrap

# Copy the locked environment file and all project code into the container
COPY environment.lock.yml /opt/ampwrap/
COPY . /opt/ampwrap/

# Create the Conda environment using the locked dependencies
RUN micromamba create -y -n ampwrap -f /opt/ampwrap/environment.lock.yml && \
    micromamba clean --all --yes

# Set the shell to use the Conda environment by default
SHELL ["micromamba", "run", "-n", "ampwrap", "/bin/bash", "-c"]

# Run the AmpWrap script using Python inside the Conda environment
ENTRYPOINT ["micromamba", "run", "-n", "ampwrap", "python", "/opt/ampwrap/ampwrap/ampwrap"]
