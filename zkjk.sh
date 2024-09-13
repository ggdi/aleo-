#!/bin/bash

LOG_FILE="/路径/prover.log"   # 日志文件路径
CHECK_INTERVAL=60                                  # 检查间隔，单位为秒
STARTUP_DELAY=300                                   # 初始启动检测延迟（5分钟 = 300秒）
POST_RESTART_DELAY=300                               # 重启后检测延迟（5分钟 = 300秒）
STOP_COMMAND="pkill -9 aleo_prover"                # 停止程序的命令
START_COMMAND="/路径/aleo_prover" # 启动程序的命令

LAST_TIMESTAMP=""                         # 上次检测到的日志时间戳
IS_FIRST_RUN=true                        # 标识是否为第一次运行

# 初始延迟
echo "$(date '+%Y-%m-%d %H:%M:%S %Z'): 等待 ${STARTUP_DELAY} 秒以确保程序开始正常生成数据..."
sleep $STARTUP_DELAY

while true; do
  if [[ -f "$LOG_FILE" ]]; then  # 检查日志文件是否存在
    echo "$(date '+%Y-%m-%d %H:%M:%S %Z'): 检查日志文件..."

    # 提取最新的时间戳
    NEW_TIMESTAMP=$(grep -oP '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}' "$LOG_FILE" | tail -1)
    
    # 检查时间戳是否有更新
    if [[ "$NEW_TIMESTAMP" == "$LAST_TIMESTAMP" ]]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S %Z'): 日志时间戳未更新，考虑重启程序..."
      RESTART_NEEDED=true
    else
      echo "$(date '+%Y-%m-%d %H:%M:%S %Z'): 日志已更新，时间戳为 $NEW_TIMESTAMP。"
      LAST_TIMESTAMP="$NEW_TIMESTAMP"
      RESTART_NEEDED=false
    fi

    # 提取最新的 GPU 数据行
    NEW_GPU_DATA=$(grep "gpu\[" "$LOG_FILE" | tail -n 6)
    
    # 检查是否有 GPU 数据行
    if [[ -n "$NEW_GPU_DATA" ]]; then
      while read -r line; do
        # 提取 GPU 编号和 "1m -" 值
        GPU_ID=$(echo "$line" | grep -oP 'gpu\[\d+\]' | grep -oP '\d+')
        ONE_MIN_DATA=$(echo "$line" | grep -oP '1m - \K\S+')

        if [[ "$ONE_MIN_DATA" == "N/A" ]]; then
          # 如果 "1m -" 数据为 "N/A"，需要重启
          echo "$(date '+%Y-%m-%d %H:%M:%S %Z'): GPU $GPU_ID 的 1m 数据为 'N/A'，需要重启程序。"
          RESTART_NEEDED=true
          break
        fi
      done <<< "$NEW_GPU_DATA"
    else
      echo "$(date '+%Y-%m-%d %H:%M:%S %Z'): 没有找到 GPU 数据，请检查日志格式。"
    fi

    # 如果需要重启，则执行停止和启动命令
    if [[ "$RESTART_NEEDED" == true ]]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S %Z'): 正在重启程序..."
      eval $STOP_COMMAND
      sleep 1  # 等待1秒确保程序已停止
      eval $START_COMMAND

      # 重启后等待 5 分钟再继续检测
      echo "$(date '+%Y-%m-%d %H:%M:%S %Z'): 重启完成，等待 ${POST_RESTART_DELAY} 秒后重新开始检测..."
      sleep $POST_RESTART_DELAY
    else
      echo "$(date '+%Y-%m-%d %H:%M:%S %Z'): GPU 数据正常，日志时间戳有更新，无需重启。"
    fi
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S %Z'): 未找到日志文件 $LOG_FILE。请检查路径。"
  fi

  # 每分钟检查一次
  sleep $CHECK_INTERVAL
done
