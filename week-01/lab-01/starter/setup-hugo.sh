#!/bin/bash
#
# Hugo Setup Script for Week 01 Lab 01
# Creates a basic Hugo site with starter content
#
# Usage: ./setup-hugo.sh [site-name]
#

set -e

SITE_NAME="${1:-blog}"

echo "🚀 Creating Hugo site: $SITE_NAME"

# Create Hugo site
hugo new site "$SITE_NAME"
cd "$SITE_NAME"

# Initialize git (required for theme submodule)
git init

# Add Ananke theme
echo "📦 Adding Ananke theme..."
git submodule add https://github.com/theNewDynamic/gohugo-theme-ananke.git themes/ananke

# Create Hugo config
cat > hugo.toml <<'EOF'
baseURL = 'https://example.cloudfront.net/'
languageCode = 'en-us'
title = 'My Terraform Blog'
theme = 'ananke'

[params]
  text_color = ''
  author = ''
  favicon = ''
  site_logo = ''
  description = 'A blog deployed with Terraform, Hugo, S3, and CloudFront'
  # choose a background color from any on this page: https://tachyons.io/docs/themes/skins/ and target defined in ananke/assets/ananke/css
  background_color_class = 'bg-dark-blue'
  recent_posts_number = 3
EOF

# Create first post
echo "📝 Creating first blog post..."
hugo new content posts/hello-terraform.md

# Update the post content
cat > content/posts/hello-terraform.md <<'EOF'
---
title: "Hello Terraform!"
date: 2024-01-15
draft: false
description: "My first post deployed with Infrastructure as Code"
tags: ["terraform", "aws", "hugo"]
---

# Welcome to My Terraform Blog!

This site is deployed using modern Infrastructure as Code practices:

## Tech Stack

- **Hugo** - Fast static site generator written in Go
- **Amazon S3** - Object storage for static files
- **CloudFront** - Global CDN for fast content delivery
- **Terraform** - Infrastructure as Code

## What I Learned

In Week 01, I learned how to:

1. Create reusable Terraform modules
2. Write Terraform native tests
3. Configure S3 for static website hosting
4. Set up CloudFront with Origin Access Control
5. Deploy a Hugo site with Terraform

## Cost Analysis

Using Infracost, I estimated this infrastructure costs approximately:
- S3: ~$0.50/month
- CloudFront: ~$1-2/month (varies with traffic)

**Total: ~$1.50-2.50/month** for a globally distributed, HTTPS-enabled blog!

## Next Steps

In future labs, I'll add:
- Custom domain with Route 53
- SSL certificate with ACM
- CI/CD pipeline for automatic deployments

---

*This post was written as part of the Terraform Course - Week 01 Lab 01*
EOF

# Create a simple 404 page
mkdir -p layouts
cat > layouts/404.html <<'EOF'
{{ define "main" }}
<section class="pa3 pa5-ns bt b--black-10 black-70 bg-light-red">
  <h1 class="f3 f2-m f1-l">Page Not Found</h1>
  <p class="measure lh-copy">
    Sorry, the page you're looking for doesn't exist.
  </p>
  <a href="/" class="link dim white">← Back to Home</a>
</section>
{{ end }}
EOF

# Build the site
echo "🔨 Building Hugo site..."
hugo

echo ""
echo "✅ Hugo site created successfully!"
echo ""
echo "📁 Site structure:"
echo "   $SITE_NAME/"
echo "   ├── hugo.toml      # Site configuration"
echo "   ├── content/       # Your blog posts"
echo "   ├── themes/        # Hugo theme"
echo "   └── public/        # Built static files (upload to S3)"
echo ""
echo "📝 Next steps:"
echo "   1. Edit content/posts/hello-terraform.md with your content"
echo "   2. Run 'cd $SITE_NAME && hugo' to rebuild"
echo "   3. Upload public/ folder to S3"
echo ""
