```python
import os
import sys
import re

def parse_export_file(export_file):
    """解析导出文件，提取文件和目录信息"""
    with open(export_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 跳过文件头信息
    lines = content.split('\n')
    
    current_file = None
    current_content = []
    files_data = []
    directories = set()
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # 检测目录标记
        dir_match = re.match(r'^\[DIR\] (.*)$', line)
        if dir_match:
            dir_path = dir_match.group(1).strip()
            if dir_path:  # 空字符串表示根目录
                directories.add(dir_path)
        
        # 检测文件开始标记
        elif line.startswith('[FILE] '):
            if current_file is not None:
                # 保存上一个文件
                files_data.append({
                    'path': current_file,
                    'content': '\n'.join(current_content).rstrip()
                })
            
            # 开始新文件
            current_file = line[7:].strip()  # 移除 "[FILE] "
            current_content = []
        
        # 检测文件结束标记
        elif line.strip() == '[END FILE]':
            if current_file is not None:
                files_data.append({
                    'path': current_file,
                    'content': '\n'.join(current_content).rstrip()
                })
                current_file = None
                current_content = []
        
        # 收集文件内容
        elif current_file is not None:
            current_content.append(line)
        
        i += 1
    
    return {
        'directories': directories,
        'files': files_data
    }

def apply_changes(base_path, export_data, preview=False):
    """应用更改到本地文件系统"""
    
    # 首先创建所有需要的目录
    for dir_path in export_data['directories']:
        full_dir_path = os.path.join(base_path, dir_path)
        if not preview:
            os.makedirs(full_dir_path, exist_ok=True)
        print(f"📁 目录: {dir_path or '(根目录)'}")
    
    # 处理文件
    for file_info in export_data['files']:
        file_path = file_info['path']
        content = file_info['content']
        full_file_path = os.path.join(base_path, file_path)
        
        # 检查文件是否存在
        file_exists = os.path.exists(full_file_path)
        
        if file_exists:
            # 读取现有文件内容
            with open(full_file_path, 'r', encoding='utf-8') as f:
                existing_content = f.read()
            
            if existing_content == content:
                status = "✅ 未变化"
            else:
                status = "📝 已修改"
                if not preview:
                    with open(full_file_path, 'w', encoding='utf-8') as f:
                        f.write(content)
        else:
            status = "🆕 新建"
            if not preview:
                with open(full_file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
        
        print(f"{status} 文件: {file_path}")
    
    return len(export_data['files'])

def diff_export_file(old_export, new_export):
    """比较两个导出文件的差异（类似git diff）"""
    old_data = parse_export_file(old_export)
    new_data = parse_export_file(new_export)
    
    # 转换为集合以便比较
    old_files = {f['path'] for f in old_data['files']}
    new_files = {f['path'] for f in new_data['files']}
    
    print("📊 变更概览:")
    print(f"  新增文件: {len(new_files - old_files)}")
    print(f"  删除文件: {len(old_files - new_files)}")
    print(f"  可能修改: {len(old_files & new_files)}")
    print()
    
    # 详细比较
    old_files_dict = {f['path']: f['content'] for f in old_data['files']}
    new_files_dict = {f['path']: f['content'] for f in new_data['files']}
    
    for file_path in sorted(new_files | old_files):
        if file_path in new_files and file_path not in old_files:
            print(f"🆕 + {file_path}")
        elif file_path in old_files and file_path not in new_files:
            print(f"🗑️  - {file_path}")
        elif old_files_dict[file_path] != new_files_dict[file_path]:
            print(f"📝 * {file_path}")
    
    return new_data

def main():
    if len(sys.argv) < 3:
        print("用法:")
        print("  1. 导入项目: python import_project.py <导出文件.txt> <目标目录>")
        print("  2. 预览导入: python import_project.py <导出文件.txt> <目标目录> --preview")
        print("  3. 比较差异: python import_project.py --diff <旧导出.txt> <新导出.txt>")
        print("\n示例:")
        print("  python import_project.py all_files.txt ./restored-project")
        print("  python import_project.py all_files.txt ./restored-project --preview")
        print("  python import_project.py --diff old_export.txt new_export.txt")
        sys.exit(1)
    
    if sys.argv[1] == '--diff':
        if len(sys.argv) != 4:
            print("❌ 错误: diff模式需要两个导出文件")
            sys.exit(1)
        
        old_export = sys.argv[2]
        new_export = sys.argv[3]
        
        if not os.path.exists(old_export) or not os.path.exists(new_export):
            print("❌ 错误: 导出文件不存在")
            sys.exit(1)
        
        print(f"🔍 比较文件变化:")
        print(f"  旧文件: {old_export}")
        print(f"  新文件: {new_export}")
        print()
        
        new_data = diff_export_file(old_export, new_export)
        
        # 询问是否应用更改
        response = input("\n是否应用这些更改到当前目录？(y/N): ")
        if response.lower() == 'y':
            base_path = input("请输入目标目录路径: ").strip()
            if not base_path:
                base_path = "."
            
            if not os.path.exists(base_path):
                os.makedirs(base_path, exist_ok=True)
            
            file_count = apply_changes(base_path, new_data, preview=False)
            print(f"\n✅ 成功应用 {file_count} 个文件的更改到: {base_path}")
    
    else:
        export_file = sys.argv[1]
        target_dir = sys.argv[2]
        preview_mode = '--preview' in sys.argv
        
        if not os.path.exists(export_file):
            print(f"❌ 错误: 导出文件 '{export_file}' 不存在")
            sys.exit(1)
        
        if preview_mode:
            print("👀 预览模式 - 不会实际修改文件")
        
        try:
            # 解析导出文件
            export_data = parse_export_file(export_file)
            
            print(f"📂 解析导出文件: {export_file}")
            print(f"📦 包含: {len(export_data['directories'])} 个目录, {len(export_data['files'])} 个文件")
            print()
            
            # 应用更改
            file_count = apply_changes(target_dir, export_data, preview=preview_mode)
            
            if not preview_mode:
                print(f"\n✅ 成功导入 {file_count} 个文件到: {target_dir}")
            else:
                print(f"\n👀 预览完成，实际导入将影响 {file_count} 个文件")
        
        except Exception as e:
            print(f"❌ 导入失败: {e}", file=sys.stderr)
            sys.exit(1)

if __name__ == "__main__":
    main()
```