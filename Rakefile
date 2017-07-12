sha = `git rev-parse --short HEAD`.chomp
image_name = "r5/loggly-host-metrics-datadog-collector:#{sha}"

desc "Build Docker image"
task :build_image do
  system "docker build -t #{image_name} ."
end

desc "Push Docker image to repo"
task :push_image do
  tag = "v1.quay.io/recfive/loggly-host-metrics-datadog-collector:#{sha}"
  system "docker tag #{image_name} #{tag}"
  system "docker push #{tag}"
end
