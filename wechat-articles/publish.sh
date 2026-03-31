#!/bin/bash

# 通过 wenyan publish -f article.md 命令，可以发布目录下新增的文章
# 如何判定新增：通过git 判断是否提交过来判断某些目录下的article.md是不是新增的文件
# 过滤掉非新增的文件 没有cover.png的也要提示用户缺少图片

set -e

# 进入脚本所在目录，确保运行路径正确
cd "$(dirname "$0")"

# 查找当前目录及子目录下所有的 article.md 文件
find . -type f -name "article.md" | while read -r file; do
    # 去除开头的 ./ 前缀以便更清晰的输出（可选优化）
    clean_file=${file#./}
    clean_dir=$(dirname "$clean_file")
    
    # 通过 git log 判断文件是否曾经提交过
    # 如果 git log 输出为空，说明该文件没有历史提交记录，即为“新增”文件
    if [ -z "$(git log -1 --oneline -- "$clean_file" 2>/dev/null)" ]; then
        
        # 检查是否包含 cover.png
        if [ ! -f "$clean_dir/cover.png" ]; then
            echo "⚠️  警告: 新增文章 [$clean_file] 缺少对应的 [$clean_dir/cover.png] 图片，跳过发布。"
            continue
        fi
        
        echo "🚀 发现新增文章: $clean_file，准备发布..."
        
        # 执行发布命令
        if wenyan publish -f "$clean_file" < /dev/null; then
            echo "✅ 成功发布: $clean_file"
            
            # 自动执行 Git 提交流程
            folder_name=$(basename "$clean_dir")
            echo "📦 正在执行 Git 提交: $folder_name"
            git add "$clean_dir"
            git commit -m "docs: 发布文章 $folder_name"
        else
            echo "❌ 发布失败: $clean_file"
        fi
    fi
done

echo "🎉 所有新增文章处理完成。"

# 推送所有提交到远程仓库
echo "🚀 将本地提交推送到远程仓库..."
git add --all
git commit -m "docs: 发布文章"
git push
