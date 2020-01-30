desc "Build the Docker image"
task :build do
  sh "mkdir lib && cp ../shared/runner.rb lib/"
  sh "docker build . -t #{NAME}"
  sh "rm -rf lib"
end

desc "Push the image to DockerHub"
task :push do
  sh "docker push #{NAME}"
end
