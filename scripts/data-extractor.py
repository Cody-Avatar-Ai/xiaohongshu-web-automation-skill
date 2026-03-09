#!/usr/bin/env python3
# Data Extractor Script
# 从 browser snapshot 提取结构化数据

import json
import re
import sys
from datetime import datetime

def extract_note_data(snapshot_text):
    """从 snapshot 文本提取笔记数据"""
    
    notes = []
    
    # 匹配笔记卡片模式
    # 这里需要根据实际 snapshot 格式调整正则表达式
    pattern = r'link.*?/explore/(.*?).*?generic.*?:(.*?).*?generic.*?:(.*?)'
    
    matches = re.findall(pattern, snapshot_text, re.DOTALL)
    
    for match in matches:
        note_id, title, author = match
        
        note = {
            'note_id': note_id.strip(),
            'title': title.strip(),
            'author': author.strip(),
            'link': f'https://www.xiaohongshu.com/explore/{note_id.strip()}',
            'extract_time': datetime.now().isoformat()
        }
        
        notes.append(note)
    
    return notes

def validate_data(notes):
    """验证数据完整性"""
    
    required_fields = ['note_id', 'title', 'author', 'link']
    valid_notes = []
    
    for note in notes:
        is_valid = all(field in note and note[field] for field in required_fields)
        if is_valid:
            valid_notes.append(note)
        else:
            print(f"⚠️ 无效数据：{note}", file=sys.stderr)
    
    return valid_notes

def format_output(notes, format_type='markdown'):
    """格式化输出"""
    
    if format_type == 'json':
        return json.dumps(notes, indent=2, ensure_ascii=False)
    
    elif format_type == 'markdown':
        output = "# 提取的笔记数据\n\n"
        output += f"**提取时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n"
        output += f"**总数**: {len(notes)} 篇\n\n"
        output += "| 序号 | 标题 | 作者 | 链接 |\n"
        output += "|------|------|------|------|\n"
        
        for i, note in enumerate(notes, 1):
            title = note['title'][:20] + '...' if len(note['title']) > 20 else note['title']
            output += f"| {i} | {title} | {note['author']} | [查看]({note['link']}) |\n"
        
        return output
    
    else:
        return str(notes)

def main():
    """主函数"""
    
    if len(sys.argv) < 2:
        print("用法：data-extractor.py <snapshot_file> [output_format]", file=sys.stderr)
        print("output_format: markdown (默认), json", file=sys.stderr)
        sys.exit(1)
    
    snapshot_file = sys.argv[1]
    output_format = sys.argv[2] if len(sys.argv) > 2 else 'markdown'
    
    # 读取 snapshot 文件
    try:
        with open(snapshot_file, 'r', encoding='utf-8') as f:
            snapshot_text = f.read()
    except FileNotFoundError:
        print(f"❌ 文件不存在：{snapshot_file}", file=sys.stderr)
        sys.exit(1)
    
    # 提取数据
    notes = extract_note_data(snapshot_text)
    
    if not notes:
        print("⚠️ 未提取到任何数据", file=sys.stderr)
        sys.exit(0)
    
    # 验证数据
    valid_notes = validate_data(notes)
    
    # 输出结果
    output = format_output(valid_notes, output_format)
    print(output)
    
    # 保存报告
    report_file = f'/tmp/web-automation/extract-{datetime.now().strftime("%Y%m%d-%H%M%S")}.md'
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write(output)
    
    print(f"\n✅ 报告已保存到：{report_file}", file=sys.stderr)

if __name__ == '__main__':
    main()
