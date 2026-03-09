#!/bin/bash
# Page Checker Script
# 检查页面状态并生成报告

set -e

# 配置
SCREENSHOT_DIR="${SCREENSHOT_DIR:-/tmp/web-automation/screenshots}"
REPORT_FILE="${REPORT_FILE:-/tmp/web-automation/page-check-report.md}"

# 创建目录
mkdir -p "$SCREENSHOT_DIR"

echo "🔍 开始页面检查..."

# 1. 检查浏览器服务
echo "1️⃣ 检查浏览器服务状态..."
browser status > /tmp/browser-status.json 2>&1 || true

if grep -q '"running": true' /tmp/browser-status.json; then
    echo "✅ 浏览器服务运行正常"
else
    echo "❌ 浏览器服务未运行"
    echo "请执行：openclaw gateway restart"
    exit 1
fi

# 2. 检查网络连接
echo "2️⃣ 检查网络连接..."
if curl -s --max-time 5 https://www.xiaohongshu.com > /dev/null; then
    echo "✅ 网络连接正常"
else
    echo "❌ 网络连接异常"
    exit 1
fi

# 3. 检查飞书服务
echo "3️⃣ 检查飞书服务..."
if command -v feishu_doc &> /dev/null; then
    echo "✅ 飞书服务可用"
else
    echo "⚠️ 飞书服务不可用"
fi

# 4. 生成报告
echo "4️⃣ 生成检查报告..."

cat > "$REPORT_FILE" << EOF
# 页面检查报告

**检查时间**: $(date '+%Y-%m-%d %H:%M:%S')

## 检查结果

| 检查项 | 状态 | 说明 |
|--------|------|------|
| 浏览器服务 | ✅/❌ | 见上文 |
| 网络连接 | ✅/❌ | 见上文 |
| 飞书服务 | ✅/⚠️ | 见上文 |

## 建议

根据检查结果执行相应操作。

EOF

echo "✅ 检查完成！报告已保存到：$REPORT_FILE"
