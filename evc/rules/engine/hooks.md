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

## Pre-commit Hook

创建 `.git/hooks/pre-commit`:

```bash
#!/bin/bash

# 格式检查
echo "Running clang-format check..."
clang-format --dry-run --Werror $(git diff --cached --name-only --diff-filter=ACM '*.cpp' '*.hpp')
if [ $? -ne 0 ]; then
    echo "❌ Code format check failed. Run: clang-format -i <file>"
    exit 1
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
