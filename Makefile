# Website hostname, used to set:
# - Docker image and container names
# - path to web root (in /tmp directory)
WEBSITE=

ifndef WEBSITE
$(error WEBSITE is not set)
endif

# S3 bucket name
S3_BUCKET=$(WEBSITE)

# Look up CloudFront distribution ID based on website alias
DISTRIBUTION_ID=$(shell aws cloudfront list-distributions \
	--query 'DistributionList.Items[].{id:Id,a:Aliases.Items}[?contains(a,`$(WEBSITE)`)].id' \
	--output text)

# Look up latest release of Hugo
# https://github.com/gohugoio/hugo/releases/latest will automatically redirect
# Get Location header, and extract the version number at the end of the URL
HUGO_VERSION=$(shell curl -Is https://github.com/gohugoio/hugo/releases/latest \
	| grep -Fi Location \
	| sed -E 's/.*tag\/v(.*)/\1/g;')

default: help

build: ## Build new Docker image (if it's been a while, start here)
	@# Build the Docker image
	docker build -t $(WEBSITE) . \
		--build-arg HUGO_VER=$(HUGO_VERSION) \
		--build-arg WEB_DIR=/tmp/$(WEBSITE)
	@# Update Hugo version in netlify.toml
	perl -p -i -e "s/HUGO_VERSION.*/HUGO_VERSION = \"$(HUGO_VERSION)\"/g" netlify.toml

serve: ## Serve Hugo website locally
	@# Look up IDs of any running containers and dispose of them
	@# Prepend command with a dash to ignore errors (for example, when container doesn't exist)
	-docker ps --filter="name=$(WEBSITE)" -aq | xargs -n1 docker rm -f
	@# --bind 0.0.0.0 <- you have to set this because the default (127.0.0.1)
	@# won't work and you will cry
	docker run -d \
		--volume `pwd`:/tmp/$(WEBSITE) \
		--publish 1313:1313 \
		--name $(WEBSITE) \
		$(WEBSITE)

new-site: ## Create new Hugo site
	@# Remove themes directory if it exists
	-rm -rf themes
	@# Create a new Hugo site within current directory
	@# --force needed because of existing Dockerfile and Makefile
	docker run --rm -it \
		--volume `pwd`:/tmp/$(WEBSITE) $(WEBSITE) \
		hugo new site . --force
	@# Set baseURL to our website
	perl -p -i -e "s/baseURL.*/baseURL = \"https:\/\/$(WEBSITE)\"/g" config.toml
	@# Check out theme
	git submodule update

random-post: ## Create a random post
	@# Create a random entry
	docker run --rm -it \
		--volume `pwd`:/tmp/$(WEBSITE) $(WEBSITE) \
		hugo new post/random-`openssl rand -hex 4`.md

edit: ## Open website in a browser, open directory in VS Code
	open http://localhost:1313
	code .

clean: ## Stop and remove Docker container
	-docker stop $(WEBSITE)
	-docker rm $(WEBSITE)

deploy: ## Deploy site to AWS
	@# Delete .DS_Store files, they are the bane of existence
	find . -name "*.DS_Store" -type f -delete
	@# Remove existing public/ directory
	rm -rf public/
	@# Build site
	docker run --rm -it --volume `pwd`:/tmp/$(WEBSITE) $(WEBSITE) hugo
	@# Upload files to S3
	aws s3 sync --acl "public-read" --sse "AES256" public/ s3://$(S3_BUCKET) --exclude 'post'
	@# Invalidate caches
	aws cloudfront create-invalidation --distribution-id $(DISTRIBUTION_ID) --paths '/*'

delete-site: ## Delete the site to start over
	-rm -rf archetypes themes data layouts content static
	-rm config.toml

clean-all: ## Remove any stopped containers and dangling images
	@# Remove stopped containers
	docker ps -aq -f status=exited --no-trunc | xargs docker rm

	@# Remove dangling/untagged images
	docker images -q -f dangling=true --no-trunc | xargs docker rmi

help: ## Show me what this Makefile can do!
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: build serve new-site delete-site random-post edit clean clean-all help
