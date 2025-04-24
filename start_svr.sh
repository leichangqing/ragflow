source .venv/bin/activate
export HF_ENDPOINT=https://hf-mirror.com
export PYTHONPATH=$(pwd)
bash docker/entrypoint.sh
#bash docker/launch_backend_service.sh
