                                                使用方法
                1 下载脚本到本机：wget https://github.com/ggdi/aleo-/releases/download/V0.0.1/zkjk.sh
                
                2 修改脚本关键项目：nano zk.sh
                                  LOG_FILE="/路径/prover.log"   # 日志文件路径 将“路径”部分更换为你zk挖矿程序日志的实际路径 
                                  START_COMMAND="/路径/aleo_prover" # 启动程序的命令 将“路径”部分更换为你zk挖矿程序的实际路径 
                                  
                3 给与脚本权限 ： chmod +x zkjk.sh 
                
                4 运行脚本：./zkjk.sh >> zkjk.log 2>&1 & 
                
                5 查看监控脚本的日志：tail -f zkjk.sh 
