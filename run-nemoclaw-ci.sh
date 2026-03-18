docker run -it \
  --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ~/.nemoclaw:/root/.nemoclaw \
  -v ~/.openclaw:/root/.openclaw \
  -v ~/.openshell:/root/.openshell \
  -v ~/Documents/NemoClaw:/opt/NemoClaw \
  --name nemoclaw-cont \
  nemoclaw-dev
