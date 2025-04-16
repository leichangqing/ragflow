source .venv/bin/activate
export PYTHONPATH=$(pwd)
export HF_ENDPOINT=https://hf-mirror.com
JEMALLOC_PATH=$(pkg-config --variable=libdir jemalloc)/libjemalloc.so;
LD_PRELOAD=$JEMALLOC_PATH python rag/svr/task_executor.py 1;
python api/ragflow_server.py;
