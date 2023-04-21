# Problem statement

Using Jenkins we are deploying a PHP monolitic service. Which must used the PHP version 7.4.33 version.

Please fix the Dockerfile, so that the image can be built with Jenkins 2.400 and PHP 7.4.33

## Build the Docker container

Generate the container image

```sh
./generate.sh {IMAGE_TAG}

e.g.

./generate.sh 0.1
