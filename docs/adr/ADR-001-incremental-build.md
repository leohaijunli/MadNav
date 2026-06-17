# ADR-001：增量构建策略

## 状态：已采纳  2026-06-17

## 决策
不整体引入 MagNav.jl，而是从其源码中按需逐步复制所需文件，
每次只添加一个模块，添加后立即测试验证。

## 添加新模块的步骤
1. 确定需要的功能
2. 找到 MagNav.jl 中对应的源文件
3. 复制到 src/，删除本项目不需要的部分
4. 识别该文件用到的外部符号
5. pkg> add 对应的包
6. 在 MadNav.jl 顶部添加 using，底部添加 include
7. 写最小测试，julia --project test/runtests.jl
8. git commit
