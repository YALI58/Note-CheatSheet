```python

# export_project.py
import os
import sys
import re

def should_include_path(rel_path):
    """判断相对路径是否属于需要导出的核心项目文件"""
    rel_path = rel_path.replace(os.sep, '/')
    # 明确包含的路径前缀
    include_prefixes = [
        'src/main/java',
        'src/main/resources',
        'src/test',
        'pom.xml'
    ]
    return any(rel_path.startswith(prefix) for prefix in include_prefixes)

def filter_java_content(content):
    """过滤Java文件内容：移除import语句和注释"""
    lines = content.split('\n')
    filtered_lines = []
    
    in_block_comment = False
    
    for line in lines:
        # 处理块注释
        if in_block_comment:
            if '*/' in line:
                in_block_comment = False
                # 只保留块注释后的内容
                line = line.split('*/', 1)[-1]
            else:
                continue  # 跳过块注释内的所有行
        
        # 移除行内块注释
        if '/*' in line and '*/' in line:
            line = re.sub(r'/\*.*?\*/', '', line)
        elif '/*' in line:
            in_block_comment = True
            line = line.split('/*')[0]
            # 继续处理这一行，可能块注释后面还有代码
        
        # 跳过import语句
        if line.strip().startswith('import '):
            continue
        
        # 移除单行注释
        line = re.sub(r'//.*', '', line)
        
        # 只保留非空行
        if line.strip():
            filtered_lines.append(line)
    
    return '\n'.join(filtered_lines)

def export_project_core(folder_path, output_file):
    """只导出项目核心代码（Java 源码、资源、测试、pom.xml），并过滤Java内容"""
    try:
        with open(output_file, 'w', encoding='utf-8') as f_out:
            f_out.write("# PROJECT CORE EXPORT FILE #\n")
            f_out.write(f"# SOURCE: {os.path.abspath(folder_path)}\n")
            f_out.write("# INCLUDED: src/main/java, src/main/resources, src/test, pom.xml\n")
            f_out.write("# FILTERED: Java import statements and comments removed\n\n")

            written_dirs = set()

            for root, dirs, files in os.walk(folder_path):
                rel_root = os.path.relpath(root, folder_path).replace(os.sep, '/')
                if rel_root == '.':
                    rel_root = ''

                # 遍历文件
                for file in files:
                    rel_file = os.path.join(rel_root, file).replace(os.sep, '/')
                    if not should_include_path(rel_file):
                        continue

                    # 写入目录（去重）
                    dir_path = rel_root if rel_root else ''
                    if dir_path not in written_dirs:
                        f_out.write(f"[DIR] {dir_path}\n")
                        written_dirs.add(dir_path)

                    f_out.write(f"[FILE] {rel_file}\n")
                    file_path = os.path.join(root, file)
                    try:
                        with open(file_path, 'r', encoding='utf-8') as f_in:
                            content = f_in.read()
                            
                            # 对Java文件应用过滤
                            if rel_file.endswith('.java'):
                                content = filter_java_content(content)
                            
                            f_out.write(content)
                    except UnicodeDecodeError:
                        f_out.write("[BINARY FILE CONTENT NOT EXPORTED]\n")
                    except Exception as e:
                        f_out.write(f"[ERROR READING FILE: {str(e)}]\n")
                    f_out.write("\n[END FILE]\n\n")

            f_out.write("# END OF EXPORT #\n")
        print(f"✅ 成功导出项目核心到: {output_file}")
    except Exception as e:
        print(f"❌ 导出失败: {e}", file=sys.stderr)

def main():
    if len(sys.argv) != 3:
        print("用法: python export_project.py <项目根目录> <输出文件.txt>")
        print("示例: python export_project.py ./bank-loan-system core_export.txt")
        sys.exit(1)

    project_root = sys.argv[1]
    output_file = sys.argv[2]

    if not os.path.isdir(project_root):
        print(f"❌ 错误: '{project_root}' 不是有效目录", file=sys.stderr)
        sys.exit(1)

    export_project_core(project_root, output_file)

if __name__ == "__main__":
    main()

```