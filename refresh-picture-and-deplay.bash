#!/bin/bash

# 配置信息
REPO="ycltpe/beauty"   # 替换为仓库，例如 ycltpe/beauty
API_URL="https://blog-mix-api.kanfang.online/api/x-posts?sort=newest&page=1&size=50"
IMAGES_DIR="docs/public/images"

echo "=== 开始刷新图片并部署 ==="

# 1. 检查必要的工具
if ! command -v curl &> /dev/null; then
    echo "错误：需要安装 curl"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "错误：需要安装 jq，请运行: brew install jq"
    exit 1
fi

# 2. 删除 docs/public/images 所有文件
echo "步骤1：删除旧图片..."
if [ -d "$IMAGES_DIR" ]; then
    rm -rf "$IMAGES_DIR"/*
    echo "✓ 已删除 $IMAGES_DIR 中的所有文件"
else
    mkdir -p "$IMAGES_DIR"
    echo "✓ 创建目录 $IMAGES_DIR"
fi

# 3. 获取API数据并下载图片（优化内存使用）
echo "步骤2：获取API数据..."

# 使用临时文件避免大数据在内存中存储
temp_file=$(mktemp)
url_temp_file=$(mktemp)
trap "rm -f $temp_file $url_temp_file" EXIT

# 流式下载API响应到临时文件
if ! curl -s "$API_URL" -o "$temp_file"; then
    echo "错误：无法访问API"
    exit 1
fi

echo "✓ API响应获取成功"

# 提取所有 localImageUrls（流式处理）
echo "步骤3：提取图片URL..."

# 使用jq流式处理，根据实际API格式提取图片URL
jq -r '.[]?.localImageUrls[]? // empty' "$temp_file" 2>/dev/null | \
    grep -v "^null$" | \
    grep -v "^$" | \
    grep -E "\.(jpg|jpeg|png|gif|webp|JPG|JPEG|PNG|GIF|WEBP)(\?.*)?$" | \
    sort | \
    uniq > "$url_temp_file"

# 检查是否找到图片URL
if [ ! -s "$url_temp_file" ]; then
    echo "警告：未找到有效的图片URL"
    echo "调试信息：检查API响应格式..."
    echo "API响应的前100个字符:"
    head -c 100 "$temp_file" && echo
    exit 0
else
    image_count=$(wc -l < "$url_temp_file" | tr -d ' ')
    echo "✓ 找到 $image_count 个图片URL"
    echo "示例 URL:"
    head -3 "$url_temp_file" | sed 's/^/  - /'
fi

# 4. 下载图片（从临时文件读取URL）
echo "步骤4：下载图片..."
download_count=0
failed_count=0

# 从临时文件逐行读取URL（避免内存问题）
while IFS= read -r url; do
    if [ -n "$url" ]; then
        # 提取文件名（处理URL参数和路径）
        # 从像http://192.168.31.63:9000/box/q0CFf0CV/G1MhHg3aQAAeNuC_973.jpg这样的URL中提取文件名
        filename=$(echo "$url" | sed 's/\?.*$//' | sed 's|.*/||')
        
        # 确保文件名有效且有扩展名
        if [ -z "$filename" ] || [ "$filename" = "/" ] || [[ ! "$filename" =~ \. ]]; then
            # 如果没有有效文件名，从 URL 中提取 ID 或生成随机名
            url_id=$(echo "$url" | grep -o '[^/]*\.jpg\|[^/]*\.jpeg\|[^/]*\.png\|[^/]*\.gif\|[^/]*\.webp' | head -1)
            if [ -n "$url_id" ]; then
                filename="$url_id"
            else
                filename="image_$(date +%s)_$((RANDOM % 10000)).jpg"
            fi
        fi
        
        echo -n "下载: $filename ... "
        
        # 下载图片，添加更多的curl参数以处理复杂URL
        if curl -s -L \
            --max-time 30 \
            --retry 2 \
            --retry-delay 1 \
            --user-agent "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
            --referer "https://blog-mix-api.kanfang.online/" \
            "$url" -o "$IMAGES_DIR/$filename"; then
            
            # 检查下载的文件是否有效（大于1KB且是图片格式）
            file_size=$(stat -f%z "$IMAGES_DIR/$filename" 2>/dev/null || stat -c%s "$IMAGES_DIR/$filename" 2>/dev/null || echo 0)
            if [ "$file_size" -gt 1024 ]; then
                # 简单检查文件是否为图片（检查文件头）
                file_type=$(file "$IMAGES_DIR/$filename" 2>/dev/null || echo "unknown")
                if echo "$file_type" | grep -i -E "(jpeg|jpg|png|gif|webp|image)" > /dev/null; then
                    download_count=$((download_count + 1))
                    echo "✓ 成功 (${file_size} bytes)"
                else
                    rm -f "$IMAGES_DIR/$filename"
                    failed_count=$((failed_count + 1))
                    echo "✗ 不是有效图片格式"
                fi
            else
                rm -f "$IMAGES_DIR/$filename"
                failed_count=$((failed_count + 1))
                echo "✗ 文件太小 (${file_size} bytes)"
            fi
        else
            failed_count=$((failed_count + 1))
            echo "✗ 下载失败"
        fi
        
        # 添加小延迟避免请求过于频繁
        sleep 0.1
    fi
done < "$url_temp_file"

echo "✓ 完成下载，成功: $download_count, 失败: $failed_count"

# 5. Git 操作
echo "步骤5：Git 提交..."

# 检查是否有变更
if [ -z "$(git status --porcelain)" ]; then
    echo "没有文件变更，无需提交"
    exit 0
fi

# 添加所有变更
git add .
if [ $? -ne 0 ]; then
    echo "错误：git add 失败"
    exit 1
fi

# 提交变更
commit_message="📸 刷新图片: 更新了 $download_count 张图片 $(date '+%Y-%m-%d %H:%M:%S')"
git commit -m "$commit_message"
if [ $? -ne 0 ]; then
    echo "错误：git commit 失败"
    exit 1
fi

echo "✓ Git 提交成功: $commit_message"

# 推送到远程
echo "步骤6：推送到GitHub..."
git push origin main || git push origin master
if [ $? -eq 0 ]; then
    echo "✓ 推送成功！"
else
    echo "错误：推送失败"
    exit 1
fi

echo "=== 🎉 刷新图片并部署完成！ ==="
echo "📊 统计信息："
echo "  - 下载图片数量: $download_count"
echo "  - 提交信息: $commit_message"
echo "  - 仓库: $REPO"