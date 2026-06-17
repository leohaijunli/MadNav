# MadNav.jl

多 UAV 磁异常导航系统。

## 开发状态

增量构建中，见 `docs/dev_log.md`。

## 快速开始

```bash
cd MadNav
julia --project                   # 进入 REPL
julia --project test/runtests.jl  # 运行测试
```

## 添加新模块流程

```
1. 找到源文件（MagNav.jl 或自研）
2. 复制到 src/
3. julia --project -e 'using Pkg; Pkg.add("需要的包")'
4. 在 src/MadNav.jl 添加 using 和 include
5. 写测试，运行验证
6. git commit -m "feat: add XxxModule"
```
