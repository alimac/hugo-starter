# Base image is Ubuntu 18
FROM ubuntu:artful

# Argument: Hugo version
ARG HUGO_VER

# Argument: web directory path
ARG WEB_DIR

# Install curl
RUN apt-get -qq update && apt-get -qq install curl

# Download latest Hugo
RUN curl -s -L https://github.com/gohugoio/hugo/releases/download/v${HUGO_VER}/hugo_${HUGO_VER}_Linux-64bit.deb -o hugo.deb

# Install hugo
RUN dpkg -i hugo.deb

# Create website directory
RUN mkdir -p $WEB_DIR

# Switch to website directory
WORKDIR $WEB_DIR

# Run Hugo
CMD ["hugo", "server", "--watch", "--buildDrafts", "--bind", "0.0.0.0"]
