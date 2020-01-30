desc "Build the Docker image"
task :build do
  sh "mkdir lib && cp ../shared/runner.rb lib/" # Don't forget to add COPY lib ./ to your Dockerfile.
  sh "docker build . -t #{NAME}"
  sh "rm -rf lib"
end

desc "Push the image to DockerHub"
task :push do
  sh "docker push #{NAME}"
end
