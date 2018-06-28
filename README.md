# A template for static website projects

## Tools!

- [Docker](https://www.docker.com/docker-mac)
- [Make](https://stackoverflow.com/questions/1469994/using-make-on-osx)
- A [Netlify](https://www.netlify.com/) account or an [Amazon AWS](https://aws.amazon.com/) account ($$)
- GitHub, GitLab or Bitbucket account (if using Netlify)
- [Terraform](https://www.terraform.io/intro/getting-started/install.html) (for AWS)
- [Hugo](https://gohugo.io/)

Terraform, Hugo, and Docker are all tools built with Go!

## Blog posts!

- [Static Websites with S3 and Hugo, Part 1](https://alimac.io/static-websites-with-s3-and-hugo-part-1/) covers setting up a static website on AWS Simple Storage Service (S3) with Terraform
- [Static Websites with S3 and Hugo, Part 2](https://alimac.io/static-websites-with-s3-and-hugo-part-2/) covers building and deploy a static website, with a little help from Docker and Hugo.

## Build a site

Clone this repo:
```
git clone --recurse-submodules git@github.com:alimac/hugo-starter.git
cd hugo-starter
```

- `make`
- `make help`
- Set WEBSITE
- `make build`
- `make new-site`
- Update config.toml to add `theme = "ananke"`
- `make serve`
- `make edit`
- `make random-post`

Basic theme configuration:
```
# Put links to main sections in the menu bar
SectionPagesMenu = "main"

[params]
  description = "Building static sites with Docker, Hugo, Terraform, and Netlify."
  twitter = "https://twitter.com/womenwhogo_chi"

[permalinks]
  post = "/:slug/"
  ```

Visit [ananke theme](https://themes.gohugo.io/gohugo-theme-ananke/) for more details, or explore other [Hugo themes](https://themes.gohugo.io/).
