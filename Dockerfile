FROM ruby:3.2.2-bullseye

RUN apt-get update && apt-get install -y \
    xvfb \
    wget \
    xfonts-75dpi \
    && rm -rf /var/lib/apt/lists/*

# Install Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
  && apt-get update && apt-get install -y yarn

  # Rails logger output to STDOUT only
ENV RAILS_LOG_TO_STDOUT=1

ENV APP_HOME=/myapp
WORKDIR ${APP_HOME}

ENV GEM_HOME /gems
ENV GEM_PATH /gems


# Add /gems/bin to the path so any installed gem binaries are runnable from bash.
ENV PATH /gems/bin:$PATH

ENV BUNDLE_JOBS 4

# How many times Bundler will retry a gem download. Optional!
ENV BUNDLE_RETRY 3

ENV RAILS_ENV development

# Install ruby dependencies
COPY Gemfile $APP_HOME/Gemfile
COPY Gemfile.lock $APP_HOME/Gemfile.lock

# Install gems
COPY Gemfile* ./
RUN bundle install

# Copy application code
COPY . $APP_HOME/

# Add entrypoint script
# COPY application.yml.example application.yml
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# Start Rails server
CMD ["rails", "server", "-b", "0.0.0.0"]
