---
paths:
  - "**/*.cpp"
  - "**/*.hpp"
  - "**/*.hlsl"
  - "**/*.glsl"
  - "**/CMakeLists.txt"
---
# 引擎提交前检查钩子

## 提交前必须运行

```bash
# 格式检查
clang-format --dry-run --Werror src/*.cpp src/*.hpp

# 静态分析
clang-tidy src/*.cpp -- -std=c++20

# 构建
cmake --build build

# CPU 侧测试
ctest --test-dir build -L cpu --output-on-failure

# GPU 侧测试（如有 GPU 环境）
ctest --test-dir build -L gpu --output-on-failure

# 性能基准（可选）
ctest --test-dir build -L performance --output-on-failure
```

## 推荐 CI 流水线

### Linux CI

```yaml
# .github/workflows/linux.yml
steps:
  - name: Install Dependencies
    run: |
      sudo apt-get install -y clang-format clang-tidy

  - name: Format Check
    run: clang-format --dry-run --Werror src/*.cpp src/*.hpp

  - name: Static Analysis
    run: clang-tidy src/*.cpp -- -std=c++20

  - name: Build
    run: |
      cmake -B build -DCMAKE_BUILD_TYPE=Debug
      cmake --build build -j

  - name: Test (CPU)
    run: ctest --test-dir build -L cpu --output-on-failure

  - name: Test (AddressSanitizer)
    run: |
      cmake -B build-asan -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined"
      cmake --build build-asan
      ctest --test-dir build-asan --output-on-failure
```

### Windows CI

```yaml
# .github/workflows/windows.yml
steps:
  - name: Build (MSVC)
    run: |
      cmake -B build -G "Visual Studio 17 2022" -A x64
      cmake --build build --config Debug

  - name: Test (CPU)
    run: ctest --test-dir build -C Debug -L cpu --output-on-failure
```

## Pre-commit Hook (SVN)

创建 SVN pre-commit hook（服务器端 `hooks/pre-commit`）:

```bash
#!/bin/bash

# SVN pre-commit hook
# 保存到服务器：/path/to/repo/hooks/pre-commit

REPOS="$1"
TXN="$2"

# 获取提交的文件列表
SVNLOOK=/usr/bin/svnlook

# 检查提交信息格式
$SVNLOOK log -t "$TXN" "$REPOS" | grep -E "^(feat|fix|perf|refactor|docs|test|chore)\([^)]+\):" > /dev/null
if [ $? -ne 0 ]; then
    echo "❌ 提交信息格式错误。格式：<type>(<scope>): <description>" >&2
    echo "示例：feat(rhi): add D3D12 buffer creation" >&2
    exit 1
fi

# 检查文件类型（只检查 .cpp/.hpp 文件）
CHANGED_FILES=$($SVNLOOK changed -t "$TXN" "$REPOS" | grep -E "^[AUD].*\.(cpp|hpp)$" | awk '{print $2}')

if [ -z "$CHANGED_FILES" ]; then
    exit 0
fi

echo "✅ Pre-commit check passed"
exit 0
```

## 客户端提交前检查脚本

创建本地检查脚本 `scripts/pre-commit-check.sh`:

```bash
#!/bin/bash

# 格式检查
echo "Running clang-format check..."
FILES=$(svn status | grep -E "^[AM].*\.(cpp|hpp)$" | awk '{print $2}')
if [ -n "$FILES" ]; then
    clang-format --dry-run --Werror $FILES
    if [ $? -ne 0 ]; then
        echo "❌ Code format check failed. Run: clang-format -i <file>"
        exit 1
    fi
fi

# 构建检查
echo "Running build check..."
cmake --build build --target EngineCore
if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

# 测试检查（快速）
echo "Running quick tests..."
ctest --test-dir build -L cpu --output-on-failure
if [ $? -ne 0 ]; then
    echo "❌ Tests failed"
    exit 1
fi

echo "✅ All checks passed"
echo "Ready to commit: svn commit -m \"<type>(<scope>): <description>\""
```

## Shader 编译检查

```bash
# HLSL 编译检查
for file in shaders/*.hlsl; do
    dxc -T vs_6_0 -E VSMain "$file" 2>/dev/null
    dxc -T ps_6_0 -E PSMain "$file" 2>/dev/null
done
```

## 内存泄漏检查

```bash
# 使用 Valgrind (Linux)
valgrind --leak-check=full ./build/tests/engine_tests

# 使用 AddressSanitizer
cmake -B build-asan -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined"
cmake --build build-asan
ctest --test-dir build-asan --output-on-failure
```
