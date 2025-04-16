以下是将你提供的内容转换为Markdown格式的版本：

---

# RAGFlow 源码安装指南

## 官网文档
- [RAGFlow 快速入门文档](https://ragflow.io/docs/dev/)
- [从源码启动 RAGFlow 服务](https://ragflow.io/docs/dev/launch_ragflow_from_source)

## 源码安装注意事项

### 1. Python 3.12 环境
- Windows、Mac 和 Linux 下的包或环境路径可能有差异。
- 可能需要手动修改 `pyproject.toml` 文件，或者直接进入虚拟环境后使用 `pip3` 安装。
- 或者通过修改环境变量来解决依赖问题。
- 在虚拟目录下使用 `pip3` 进行安装。
- `datrie` 安装可能会比较复杂，可以参考 [RPM 资源页面](https://rpmfind.net/linux/rpm2html/search.php?query=python312-datrie(x86-64)。

例如，如果 `pyicu` 安装失败：
```bash
sudo apt-get update
sudo apt-get install pkg-config libicu-dev
source .venv/bin/activate
pip3 install --no-binary=:pyicu: pyicu
# 验证
python -c "import icu; print(icu.__version__)"
```

### 2. 虚拟环境
```bash
git clone https://github.com/infiniflow/ragflow.git
cd ragflow/
# 如果未安装 pipx，请先安装
pip3 install pipx
# 或者
sudo apt install pipx

pipx install uv  # 它会创建 .venv，如果缺少包，激活后使用 pip 安装
export CFLAGS="-Wno-error=incompatible-pointer-types" 
export CXXFLAGS="-Wno-error=incompatible-pointer-types"
uv sync --python 3.12 --all-extras
```

### 3. 安装依赖服务（Docker）
如果尚未安装以下服务，请运行：
```bash
docker compose -f docker/docker-compose-base.yml up -d
```

### 4. 配置 `.env` 文件
- 将 `.env` 文件中的主机指向 Docker 主机的 IP 地址。
- 如果使用 macOS，请取消 `macos=1` 的注释。

### 5. 配置 `conf/service_conf.yaml.template`
- 将 5 个资源节点的 `host` 指向 Docker 主机的 IP 地址，直接写 IP 地址。
- 示例：
```yaml
mysql:
  name: '${MYSQL_DBNAME:-rag_flow}'
  user: '${MYSQL_USER:-root}'
  password: '${MYSQL_PASSWORD:-infini_rag_flow}'
  host: '101.15.113.113'  # 替换为实际 IP
  port: 5455
```

### 6. 修改 `pyproject.toml`
因为 macOS 下 `torch` 包与 Linux 的要求不同：
```toml
"xgboost==1.6.0",  # 原始版本为 1.5.0
"debugpy>=1.8.13",
"threadpoolctl>=3.6.0",  # 增加

[project.optional-dependencies]
full = [
    "bcembedding==0.1.5",
    "fastembed>=0.3.6,<0.4.0; sys_platform == 'darwin' or platform_machine != 'x86_64'",
    "fastembed-gpu>=0.3.6,<0.4.0; sys_platform != 'darwin' and platform_machine == 'x86_64'",
    "flagembedding==1.2.10",
    "torch>=2.0.0,<2.2.2; sys_platform == 'darwin' or platform_machine != 'x86_64'",
    "torch>=2.4.0,<2.5.1; sys_platform != 'darwin' and platform_machine == 'x86_64'",
    "transformers>=4.35.0,<5.0.0"
]
```

### 7. 安装其他包
为了避免报错 `Fatal Python error: Segmentation fault`：
```bash
source .venv/bin/activate
brew install libjemalloc
pip3 install aiohttp==3.11.13
pip3 install google-cloud-aiplatform==1.64.0
pip3 install akracer==0.0.13
```

### 8. 修改 `docker/entrypoint.sh`
因为 macOS 下不是 `.so` 动态库：
```bash
function task_exe() {
    local consumer_id="$1"
    local host_id="$2"
    # for macos 
    #JEMALLOC_PATH="$(pkg-config --variable=libdir jemalloc)/libjemalloc.2.dylib"
    # for linux
    JEMALLOC_PATH="$(pkg-config --variable=libdir jemalloc)/libjemalloc.so"
    while true; do
    	  # for macos
        # DYLD_INSERT_LIBRARIES "$JEMALLOC_PATH" \
    		# for linux
        LD_PRELOAD="$JEMALLOC_PATH" \
        "$PY" rag/svr/task_executor.py "${host_id}_${consumer_id}"
    done
}
```

### 9. 配置 VSCode 的 `launch.json`
新增 `.vscode/launch.json` 文件：
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: ragflow_server",
            "type": "debugpy",
            "request": "launch",
            "program": "${workspaceFolder}/api/ragflow_server.py",
            "justMyCode": true,
            "cwd": "${workspaceFolder}", // 设置工作目录为项目根目录
            "console": "integratedTerminal",
            "env": {
                "HF_ENDPOINT": "https://hf-mirror.com",
                "PYTHONPATH": "${workspaceFolder}",
                "VIRTUAL_ENV": "${workspaceFolder}/.venv",  // 设定虚拟环境路径
                "PATH": "${workspaceFolder}/.venv/bin:${env:PATH}",  // 将虚拟环境的 bin 目录添加到 PATH
            },
            "envFile": "${workspaceFolder}/docker/.env",
            "args": []
        },
        {
            "name": "Python: task_executor",
            "type": "debugpy",
            "request": "launch",
            "program": "${workspaceFolder}/rag/svr/task_executor.py",
            "justMyCode": true,
            "cwd": "${workspaceFolder}", // 设置工作目录为项目根目录
            "console": "integratedTerminal",
            "env": {
                "HF_ENDPOINT": "https://hf-mirror.com",
                "PYTHONPATH": "${workspaceFolder}",
                "VIRTUAL_ENV": "${workspaceFolder}/.venv",  // 设定虚拟环境路径
                "PATH": "${workspaceFolder}/.venv/bin:${env:PATH}",  // 将虚拟环境的 bin 目录添加到 PATH
                //"LD_PRELOAD": "$(pkg-config --variable=libdir jemalloc)/libjemalloc.so", // Linux
                "DYLD_INSERT_LIBRARIES": "/usr/local/Cellar/jemalloc/5.3.0/lib/libjemalloc.2.dylib", // macOS
            },
            "envFile": "${workspaceFolder}/docker/.env",
            "args": []
        }
    ]
}
```

### 10. 安装 npm
```bash
sudo apt update
sudo apt install curl
curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
# build 前端
cd $ragflow/web
npm install

# 更新 .umirc.ts文件 proxy.target为 http://127.0.0.1:9380:
vim .umirc.ts
#启动前端服务
npm run dev 
```

### 11. 启动和停止服务
- **控制台启动**
  - 后台服务：
    ```bash
    cd $ragflow/
    ./start_svr.sh  # 开启 task_executor 和 ragflow_server 两个进程
    ```
    # 启动时报错：ntlk
    ```bash
    source .venv/bin/activate
    python
    >>> import nltk
    >>> nltk.download('punkt_tab')
    >>> nltk.download('wordnet')
    ```
    # 启动时报错：libodbc.so.2
    ```bash
    sudo apt update
		sudo apt install -y unixodbc unixodbc-dev
		# 验证
		ldconfig -p | grep libodbc.so.2
    ```
  - 前端服务：
    ```bash
    cd $ragflow/web
    npm build
    npm run dev
    ```

- **控制台停止**
  ```bash
  $/ragflow/stop_svr.sh
  ```
  有时候可能需要手动 `kill -9` 进程。

### 12. 环境验证
- ELK：[http://10.5.161.17:1200/](http://10.5.161.17:1200/)
- Kibana：[http://10.5.161.17:6601/](http://10.5.161.17:6601/)
- 前端：[http://10.5.161.17:9222](http://10.5.161.17:9222)

### 13. 安装 jemalloc
```bash
wget https://github.com/jemalloc/jemalloc/releases/download/5.3.0/jemalloc-5.3.0.tar.bz2
tar -xjf jemalloc-5.3.0.tar.bz2
./configure
make
sudo make install
#验证
ls $(pkg-config --variable=libdir jemalloc)/libjemalloc.so