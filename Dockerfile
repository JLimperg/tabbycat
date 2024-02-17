# Docker file lists all the commands needed to setup a fresh linux instance to
# run the application specified. docker-compose does not use this.

# Grab a python image
FROM python:3.9

WORKDIR /tcd

# Just needed for all things python (note this is setting an env variable)
ENV PYTHONUNBUFFERED 1
# Needed for correct settings input
ENV IN_DOCKER 1
# Set git to use HTTPS (SSH is often blocked by firewalls)
RUN git config --global url."https://".insteadOf git://

# Setup Node/NPM
RUN apt-get update && \
    apt-get install -y curl nginx && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean

# Install our node/python requirements
RUN pip install pipenv
ADD Pipfile Pipfile.lock /tcd/
RUN pipenv install --system --deploy && \
    pipenv --clear
ADD package.json package-lock.json /tcd/
RUN npm ci --omit=dev && \
    npx update-browserslist-db@latest && \
    npm cache clean --force

# Copy all our files
ADD babel.config.js crowdin.yml ProcfileMulti.docker render.yaml vue.config.js /tcd/
ADD bin/ /tcd/bin/
ADD config/ /tcd/config/
ADD data/ /tcd/data/
ADD tabbycat/ /tcd/tabbycat/

# Compile all the static files
RUN npm run build
RUN python ./tabbycat/manage.py collectstatic --noinput -v 0
