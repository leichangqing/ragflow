source .venv/bin/activate
export PYTHONPATH=$(pwd)
export HF_ENDPOINT=https://hf-mirror.com
#JEMALLOC_PATH=$(pkg-config --variable=libdir jemalloc)/libjemalloc.so;
#LD_PRELOAD=$JEMALLOC_PATH python rag/svr/task_executor.py 1;
JEMALLOC_PATH=/usr/local/Cellar/jemalloc/5.3.0/lib/libjemalloc.2.dylib;
DYLD_INSERT_LIBRARIES=$JEMALLOC_PATH python -X faulthandler rag/svr/task_executor.py 1;
#python api/ragflow_server.py;
