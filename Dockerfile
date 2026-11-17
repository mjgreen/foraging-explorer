FROM docker.io/rocker/r-ver:4.5.1@sha256:03b023fbf7b1b24ac1bb8b2ac5fd7e15a767e67b40ff50c155e328110981c2aa
RUN apt-get update \
 && apt-get install -y --no-install-recommends pkg-config zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /opt/foraging
COPY app.R renv.lock ./
COPY scripts/setup.R scripts/setup.R
RUN Rscript --vanilla scripts/setup.R
COPY . .
RUN Rscript --vanilla -e '.libPaths(c(normalizePath(".foraging-library"), .libPaths())); source("tests/test_simulation.R"); source("tests/test_demo.R")' \
 && useradd --uid 10001 --create-home foraging
USER 10001:10001
EXPOSE 3838
CMD ["Rscript", "--vanilla", "scripts/run.R", "--host=0.0.0.0", "--port=3838"]
