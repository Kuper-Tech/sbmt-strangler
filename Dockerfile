ARG RUBY_VERSION

FROM dreg.sbmt.io/dhub/library/ruby:$RUBY_VERSION

ARG BUNDLER_VERSION
ARG RUBYGEMS_VERSION

ENV BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3

RUN gem update --system ${RUBYGEMS_VERSION} \
  && gem install --default bundler:${BUNDLER_VERSION}
