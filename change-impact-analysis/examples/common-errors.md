# 常见错误与解决方案

## 1. 路由映射生成相关

### ❌ 路由文件未被扫描到

**症状**：某个模块的路由没有出现在映射表中。

**原因**：
- 路由文件不叫 `router.ts` / `routes.ts`（如叫 `routing.ts`、`index.ts`）
- 路由文件在 `src/client/` 或 `src/assets/` 下被过滤

**解决**：检查文件命名是否匹配 `/router\.[jt]sx?$/` 或 `/routes\.[jt]sx?$/`。

---

### ❌ 菜单路径显示路径分段（如 `order > refund`）

**症状**：映射表中某些路由的菜单路径仅为路径分段，非业务中文名称。

**原因**：
- 路由 `meta.title` 缺失或不含中文
- 组件文件中也未找到中文标题（组件标题回退失败）

**解决**：
1. 先检查路由的 `component` 组件文件是否有中文标题可提取（`defineOptions.name`、顶层 `title` 常量、导航栏 `title` 属性等）
2. 如果组件中没有，需要人工搜索该路由的触发入口（哪个页面 `router.push` 到这里），确认真实菜单归属后在报告中手动标注

---

### ❌ TypeScript 解析失败

**症状**：报错 `Cannot find module 'typescript'`。

**解决**：确保项目依赖中有 `typescript`，运行 `npm install` 或 `yarn`。

---

## 2. 变更文件获取相关

### ❌ git diff 无输出

**症状**：`get-changed-files.sh` 没有输出任何文件。

**原因**：
- 当前分支没有相对于 master 的变更
- 本地没有 `origin/master`（未 fetch）
- 变更文件不在 `src/` 下

**解决**：
```bash
git fetch origin master
git log --oneline HEAD...origin/master  # 确认有差异
```

---

### ❌ 排除规则过于宽泛

**症状**：想分析 `src/client/custom/` 的变更但被过滤了。

**原因**：脚本默认排除整个 `src/client/` 目录。

**解决**：修改 `get-changed-files.sh` 中的 `grep -v` 规则，或手动指定文件列表。

---

## 3. 引用分析相关

### ❌ 引用数为 0 但实际有引用

**症状**：某个公共组件显示为"内部文件"，但实际被很多地方使用。

**原因**：
- 搜索路径不对（alias 路径如 `@/` 需要展开）
- 组件通过 re-export（barrel file）间接引用，grep 搜索不到直接路径

**解决**：
- 搜索时同时匹配相对路径和 alias 路径
- 对 `index.ts` barrel file 做递归追踪

---

### ❌ Vue 文件 script 解析为空

**症状**：`.vue` 文件的导出符号列表为空。

**原因**：
- 文件使用 `<script>` 而非 `<script setup>`，且没有显式 export
- `@vue/compiler-sfc` 未安装

**解决**：确保 `@vue/compiler-sfc` 在依赖中。Vue 2 项目需要 `vue-template-compiler`。

---

## 4. 报告生成相关

### ❌ 业务触发路径描述不够清晰

**症状**：QA 反馈看不懂触发路径。

**解决方案**：
- 用"进入 XXX 页面 → 点击 XXX → 检查 XXX"的格式
- 避免使用代码术语，用业务语言
- 补充具体的数据条件（如"选择一个有课时余额的学员"）

---

### ❌ 同一组件被多个业务使用，报告太长

**解决方案**：
- 在区块二中合并同功能的引用
- 在区块三中按**业务域**而非按文件聚合

---

### ❌ 报告只在对话中输出，没有生成文件

**症状**：分析结果以文本形式回复在对话中，但项目目录下没有 `CHANGE_IMPACT_REPORT.html`。

**解决**：分析完成后必须将报告写入项目根目录的 `CHANGE_IMPACT_REPORT.html`，这是 skill 的强制输出要求。
