import ast
import io
import os
import re
import tokenize
def remove_yaml_comments(content):
    
    lines = content.split('\n')
    result = []
    in_block_scalar = False
    block_scalar_indent = 0
    for line in lines:
        if in_block_scalar:
            current_indent = len(line) - len(line.lstrip(' '))
            if line.strip() == '' or current_indent > block_scalar_indent:
                result.append(line)
                continue
            in_block_scalar = False
        new_line = _remove_yaml_line_comment(line)
        block_scalar_indent = _get_yaml_block_scalar_indent(new_line)
        if block_scalar_indent is not None:
            in_block_scalar = True
        if new_line.strip():
            result.append(new_line)
        elif line.strip() == '':
            result.append('')
    output = '\n'.join(result)
    while '\n\n\n' in output:
        output = output.replace('\n\n\n', '\n\n')
    return output
def _get_yaml_block_scalar_indent(line):
    
    if not line.strip():
        return None
    if re.search(r':\s*[>|](?:[+-]?[1-9]?|[1-9]?[+-]?)\s*$', line):
        return len(line) - len(line.lstrip(' '))
    return None
def _remove_yaml_line_comment(line):
    
    if not line.strip():
        return line
    stripped = line.lstrip()
    if stripped.startswith('#'):
        return ''
    result = []
    in_string = False
    string_char = None
    i = 0
    while i < len(line):
        char = line[i]
        if in_string:
            result.append(char)
            if char == '\\' and i + 1 < len(line):
                result.append(line[i + 1])
                i += 2
                continue
            elif char == string_char:
                in_string = False
            i += 1
        else:
            if char in ('"', "'"):
                in_string = True
                string_char = char
                result.append(char)
                i += 1
            elif char == '#':
                break
            else:
                result.append(char)
                i += 1
    return ''.join(result).rstrip()
def remove_js_comments(content):
    out = []
    STATE_CODE = 0
    STATE_LINE_COMMENT = 1
    STATE_BLOCK_COMMENT = 2
    STATE_STRING_SINGLE = 3
    STATE_STRING_DOUBLE = 4
    STATE_TEMPLATE = 5
    state = STATE_CODE
    line_has_code = False
    current_line_buffer = []
    i = 0
    n = len(content)
    while i < n:
        char = content[i]
        if state == STATE_CODE:
            if char == '/' and i + 1 < n:
                next_char = content[i + 1]
                if next_char == '/':
                    state = STATE_LINE_COMMENT
                    i += 2
                    continue
                elif next_char == '*':
                    state = STATE_BLOCK_COMMENT
                    i += 2
                    continue
            if char == "'":
                state = STATE_STRING_SINGLE
                line_has_code = True
                current_line_buffer.append(char)
                i += 1
            elif char == '"':
                state = STATE_STRING_DOUBLE
                line_has_code = True
                current_line_buffer.append(char)
                i += 1
            elif char == '`':
                state = STATE_TEMPLATE
                line_has_code = True
                current_line_buffer.append(char)
                i += 1
            elif char == '\n':
                if line_has_code:
                    out.append(''.join(current_line_buffer))
                    out.append('\n')
                current_line_buffer = []
                line_has_code = False
                i += 1
            elif char.isspace():
                current_line_buffer.append(char)
                i += 1
            else:
                line_has_code = True
                current_line_buffer.append(char)
                i += 1
        elif state == STATE_LINE_COMMENT:
            if char == '\n':
                state = STATE_CODE
                if line_has_code:
                    out.append(''.join(current_line_buffer))
                    out.append('\n')
                current_line_buffer = []
                line_has_code = False
                i += 1
            else:
                i += 1
        elif state == STATE_BLOCK_COMMENT:
            if char == '*' and i + 1 < n and content[i + 1] == '/':
                state = STATE_CODE
                i += 2
            elif char == '\n':
                if line_has_code:
                    out.append(''.join(current_line_buffer))
                    out.append('\n')
                current_line_buffer = []
                line_has_code = False
                i += 1
            else:
                i += 1
        elif state == STATE_STRING_SINGLE:
            if char == '\\' and i + 1 < n:
                current_line_buffer.append(char)
                current_line_buffer.append(content[i + 1])
                i += 2
            elif char == "'":
                current_line_buffer.append(char)
                state = STATE_CODE
                i += 1
            elif char == '\n':
                current_line_buffer.append(char)
                out.append(''.join(current_line_buffer))
                current_line_buffer = []
                i += 1
            else:
                current_line_buffer.append(char)
                i += 1
        elif state == STATE_STRING_DOUBLE:
            if char == '\\' and i + 1 < n:
                current_line_buffer.append(char)
                current_line_buffer.append(content[i + 1])
                i += 2
            elif char == '"':
                current_line_buffer.append(char)
                state = STATE_CODE
                i += 1
            elif char == '\n':
                current_line_buffer.append(char)
                out.append(''.join(current_line_buffer))
                current_line_buffer = []
                i += 1
            else:
                current_line_buffer.append(char)
                i += 1
        elif state == STATE_TEMPLATE:
            if char == '\\' and i + 1 < n:
                current_line_buffer.append(char)
                current_line_buffer.append(content[i + 1])
                i += 2
            elif char == '`':
                current_line_buffer.append(char)
                state = STATE_CODE
                i += 1
            elif char == '\n':
                current_line_buffer.append(char)
                out.append(''.join(current_line_buffer))
                current_line_buffer = []
                i += 1
            else:
                current_line_buffer.append(char)
                i += 1
    if line_has_code:
        out.append(''.join(current_line_buffer))
    result = ''.join(out)
    while '\n\n\n' in result:
        result = result.replace('\n\n\n', '\n\n')
    return result
def remove_comments_and_docstrings(content, file_type="gd"):
    
    out = []
    STATE_CODE = 0
    STATE_STRING = 1
    STATE_DOCSTRING = 2
    STATE_COMMENT = 3
    state = STATE_CODE
    string_quote = ""
    nesting = 0
    line_has_code = False
    current_line_buffer = []
    prev_line_ends_with_colon = False
    i = 0
    n = len(content)
    while i < n:
        char = content[i]
        if state == STATE_CODE:
            if char == '#':
                state = STATE_COMMENT
                i += 1
            elif char in ('"', "'"):
                is_triple = False
                quote = char
                if i + 2 < n and content[i:i+3] == char * 3:
                    is_triple = True
                    quote = char * 3
                if is_triple and nesting == 0 and not line_has_code:
                    if file_type == "py" and prev_line_ends_with_colon:
                        state = STATE_STRING
                        string_quote = quote
                        current_line_buffer.append(quote)
                        line_has_code = True
                        i += 3
                    else:
                        state = STATE_DOCSTRING
                        string_quote = quote
                        i += 3
                else:
                    state = STATE_STRING
                    string_quote = quote
                    current_line_buffer.append(quote)
                    line_has_code = True
                    i += 3 if is_triple else 1
            elif char in '([{':
                nesting += 1
                line_has_code = True
                current_line_buffer.append(char)
                i += 1
            elif char in ')]}':
                nesting = max(0, nesting - 1)
                line_has_code = True
                current_line_buffer.append(char)
                i += 1
            elif char == '\n':
                line_content = "".join(current_line_buffer).rstrip()
                prev_line_ends_with_colon = line_content.endswith(':')
                if line_has_code:
                    out.append("".join(current_line_buffer))
                    out.append(char)
                current_line_buffer = []
                line_has_code = False
                i += 1
            elif char.isspace():
                current_line_buffer.append(char)
                i += 1
            else:
                line_has_code = True
                current_line_buffer.append(char)
                i += 1
        elif state == STATE_COMMENT:
            if char == '\n':
                state = STATE_CODE
                line_content = "".join(current_line_buffer).rstrip()
                prev_line_ends_with_colon = line_content.endswith(':')
                if line_has_code:
                    out.append("".join(current_line_buffer))
                    out.append(char)
                current_line_buffer = []
                line_has_code = False
                i += 1
            else:
                i += 1
        elif state == STATE_DOCSTRING:
            if char == '\\':
                i += 2
            elif content.startswith(string_quote, i):
                state = STATE_CODE
                i += len(string_quote)
                if i < n and content[i] == '\n':
                    i += 1
            else:
                i += 1
        elif state == STATE_STRING:
            if char == '\\':
                current_line_buffer.append(char)
                if i + 1 < n:
                    current_line_buffer.append(content[i+1])
                    i += 2
                else:
                    i += 1
            elif content.startswith(string_quote, i):
                current_line_buffer.append(string_quote)
                state = STATE_CODE
                i += len(string_quote)
            elif char == '\n':
                current_line_buffer.append(char)
                out.append("".join(current_line_buffer))
                current_line_buffer = []
                i += 1
            else:
                current_line_buffer.append(char)
                i += 1
    if line_has_code:
        out.append("".join(current_line_buffer))
    result = "".join(out)
    while '\n\n\n' in result:
        result = result.replace('\n\n\n', '\n\n')
    return result

def remove_python_comments_and_docstrings(content):
    
    removal_spans = _get_python_docstring_spans(content)
    try:
        tokens = tokenize.generate_tokens(io.StringIO(content).readline)
        for token in tokens:
            if token.type == tokenize.COMMENT:
                removal_spans.append(
                    (_position_to_offset(content, token.start), _position_to_offset(content, token.end))
                )
    except tokenize.TokenError:
        return remove_comments_and_docstrings(content, "py")
    result = _remove_spans(content, removal_spans)
    while '\n\n\n' in result:
        result = result.replace('\n\n\n', '\n\n')
    return result

def _get_python_docstring_spans(content):
    
    spans = []
    try:
        tree = ast.parse(content)
    except SyntaxError:
        return spans

    def collect_docstring_span(node):
        body = getattr(node, "body", None)
        if not body:
            return
        first_stmt = body[0]
        if (
            isinstance(first_stmt, ast.Expr)
            and isinstance(first_stmt.value, ast.Constant)
            and isinstance(first_stmt.value.value, str)
        ):
            spans.append(
                (
                    _position_to_offset(content, (first_stmt.lineno, first_stmt.col_offset)),
                    _position_to_offset(content, (first_stmt.end_lineno, first_stmt.end_col_offset)),
                )
            )
        for child in body:
            if isinstance(child, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
                collect_docstring_span(child)

    collect_docstring_span(tree)
    return spans

def _position_to_offset(content, position):
    
    line_no, column = position
    lines = content.splitlines(keepends=True)
    offset = 0
    for index in range(max(0, line_no - 1)):
        if index < len(lines):
            offset += len(lines[index])
    return offset + column

def _remove_spans(content, spans):
    
    if not spans:
        return content
    merged_spans = []
    for start, end in sorted(spans):
        if not merged_spans or start > merged_spans[-1][1]:
            merged_spans.append([start, end])
        else:
            merged_spans[-1][1] = max(merged_spans[-1][1], end)
    result = []
    cursor = 0
    for start, end in merged_spans:
        result.append(content[cursor:start])
        cursor = end
    result.append(content[cursor:])
    return "".join(result)

def process_directory(root_dir, extensions=None):
    
    if extensions is None:
        extensions = ['.gd', '.py', '.yml', '.yaml', '.js', '.toml']
    print(f"Scanning directory: {root_dir}")
    print(f"Processing extensions: {extensions}")
    count = 0
    for dirpath, dirnames, filenames in os.walk(root_dir):
        if '.git' in dirnames:
            dirnames.remove('.git')
        if '__pycache__' in dirnames:
            dirnames.remove('__pycache__')
        if '.venv' in dirnames:
            dirnames.remove('.venv')
        if 'venv' in dirnames:
            dirnames.remove('venv')
        if 'node_modules' in dirnames:
            dirnames.remove('node_modules')
        for filename in filenames:
            ext = os.path.splitext(filename)[1].lower()
            if ext in extensions:
                filepath = os.path.join(dirpath, filename)
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        content = f.read()
                    if ext in ('.yml', '.yaml', '.toml'):
                        new_content = remove_yaml_comments(content)
                    elif ext == '.py':
                        new_content = remove_python_comments_and_docstrings(content)
                    elif ext == '.js':
                        new_content = remove_js_comments(content)
                    else:
                        new_content = remove_comments_and_docstrings(content, "gd")
                    if new_content != content:
                        print(f"Cleaning: {filepath}")
                        with open(filepath, 'w', encoding='utf-8') as f:
                            f.write(new_content)
                        count += 1
                except Exception as e:
                    print(f"Error processing {filepath}: {e}")
    print(f"Done. Processed {count} files.")
if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Remove comments and docstrings from source files")
    parser.add_argument("path", nargs="?", default=".", help="Directory to process")
    parser.add_argument("--ext", nargs="+", default=[".gd", ".py", ".yml", ".yaml", ".js", ".toml"],
                        help="File extensions to process (default: .gd .py .yml .yaml .js .toml)")
    args = parser.parse_args()
    process_directory(args.path, args.ext)
