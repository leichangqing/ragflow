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
python3 -c "import icu; print(icu.__version__)"
```

### 2. 虚拟环境
```bash
git clone https://github.com/infiniflow/ragflow.git
cd ragflow/
# 如果未安装 pipx，请先安装
#pip3 install pipx
# 或者
sudo apt install pipx

pipx install uv  # 它会创建 .venv，如果缺少包，激活后使用 pip 安装
#安装pyicu, datrie可能同错，参考此文后面
#export CFLAGS="-Wno-error=incompatible-pointer-types" 
#export CXXFLAGS="-Wno-error=incompatible-pointer-types"
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

### 10. 安装 nodejs18 npm10
```bash
# sudo apt update
# sudo apt install nodejs build-essential -y
# nodejs --version
sudo apt remove nodejs
sudo apt autoremove
# 环境变量
sudo GNUTLS_CPUID_OVERRIDE=0x1 apt-get update 
sudo GNUTLS_CPUID_OVERRIDE=0x1 apt install -y nodejs
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

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
    #### 启动时报错：ntlk
    ```bash
    source .venv/bin/activate
    python
    >>> import nltk
    >>> nltk.download('punkt_tab')
    >>> nltk.download('wordnet')
    ```
    #### 启动时报错：libodbc.so.2
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
sudo apt update
sudo apt -y install libjemalloc-dev
#或
wget https://github.com/jemalloc/jemalloc/releases/download/5.3.0/jemalloc-5.3.0.tar.bz2
tar -xjf jemalloc-5.3.0.tar.bz2
./configure
make
sudo make install
#验证
ls $(pkg-config --variable=libdir jemalloc)/libjemalloc.so
```

### 14. 安装 ICU
```bash
sudo apt update
sudo apt install libicu-dev
sudo apt install python3-icu
如果需要手动下载 .deb 文件安装，可以访问以下链接：
python3-icu_2.13.1-1_amd64.deb（适用于 AMD64 架构）
# 验证
python3 -c "import icu; print(icu.getUnicodeVersion())"

# 或

安装ICU4C
# 安装ICU4C
apt install libicu-dev

# 验证安装
icu-config --version
# 我这里提示没有找到icu-config命令，系统提示icu-config: command not found

# 检查libicu-dev是否正常安装
dpkg -l | grep libicu-dev
# 显示 ii  libicu-dev:amd64              74.2-1ubuntu3.1                         amd64        Development files for International Components for Unicode
# libicu-dev已经正确安装的情况下，应该是icu-config安装路径没有被添加到系统的PATH环境变量中

# 查找icu-config工具
find /root -name icu-config 2>/dev/null
# 显示 /root/miniconda3/bin/icu-config

# 添加icu-config到PATH
# 如果icu-config位于/root/miniconda3/bin/icu-config，可以将其添加到.bashrc文件中：
echo 'export PATH="/root/miniconda3/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 重新检查icu-config
icu-config --version
# 显示 73.1

安装g++
# 安装g++
apt install g++

# 确认安装情况
g++ --version

安装PyICU
# 安装PyICU
uv pip install pyicu    
原文链接：https://blog.csdn.net/qq_40224400/article/details/146076860
```

### 15. libssl
```bash
# 安装必要的开发包
sudo apt update
sudo apt install build-essential libssl-dev libncurses5-dev libsqlite3-dev libreadline-dev libtk8.6 libgdm-dev libdb4o-cil-dev libpcap-dev
sudo apt-get install libssl-dev
# 验证
python3 -c "import ssl; print(ssl.OPENSSL_VERSION)"
```

### 16. datrie安装
```bash
#二进制安装
https://pkgs.org/search/?q=datrie
#根据操作系统选相应的deb文件下载
https://ubuntu.pkgs.org/24.10/ubuntu-main-amd64/libdatrie1_0.2.13-3build1_amd64.deb.html
#找到下载链接
http://archive.ubuntu.com/ubuntu/pool/main/libd/libdatrie/libdatrie1_0.2.13-3build1_amd64.deb
#或
#Update the package index:
sudo apt update
#Install libdatrie1 deb package:
sudo apt install libdatrie1
sudo apt install python3-datrie
```
### 降级ssl
```bash
wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5_amd64.deb
sudo dpkg -i libssl1.0.0_1.0.2n-1ubuntu5_amd64.deb
wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb
# install package locally
sudo dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb
# ubuntu22.04, 安装libssl1.0
wget http://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.0.0_1.0.2g-1ubuntu4.20_amd64.deb
sudo dpkg -i libssl1.0.0_1.0.2g-1ubuntu4.20_amd64.deb
```

### 17 libodbc.so.2
```bash
    import pyodbc
ImportError: libodbc.so.2: cannot open shared object file: No such file or directory
sudo apt remove libodbc2
sudo apt install libodbc2
```
### 18 Install libgdiplus on Ubuntu 22.04
```bash
sudo apt update
sudo apt -y install libgdiplus
```
