desc "Build the Docker image"
task :build do
  sh "docker build . -t #{NAME}"
end

desc "Push the image to DockerHub"
task :push do
  sh "docker push #{NAME}"
end