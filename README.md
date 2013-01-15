# Jcs3 #

Jcs3 is a gem I created to support the process of deploying my Jekyll based static site files to the Cloudfront CDN which is backed by Amazon S3.  The two main functions of the gem are:

* Compress pertinent files with gzip
* Deploy the compressed files

## Installation ##

1. Clone this repository: git clone https://github.com/brcosm/jcs3.git
2. Build the gem: cd jcs3; gem build jcs3.gemspec
3. Install the gem: gem install jcs3
4. Use it to deploy your site: [My Rakefile](https://gist.github.com/4541735)

## Configuration ##

The gem expects the configuration hash to contain the following:

* bucket: name_of_your_s3_bucket
* access_key_id: your_access_key
* secret_access_key: your_secret_key
* cf_distribution_id: your_cloudfront_distribution_id