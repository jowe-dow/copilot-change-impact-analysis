# 速查表

## 命令速查

| 用途 | 命令 |
|------|------|
| 获取变更文件 | `bash .github/skills/change-impact-analysis/scripts/get-changed-files.sh [base_branch]` |
| 搜索文件引用 | `grep -r "from '.*<module>'" src/ --include="*.ts" --include="*.tsx" --include="*.vue" -l` |

## 文件过滤规则

| 规则 | 说明 |
|------|------|
| 包含 | 源码目录（默认 `src/`）下所有 `.ts/.tsx/.js/.jsx/.vue/.svelte` 文件 |
| 内置排除 | `assets/` — 静态资源（图片、字体等） |
| 内置排除 | `client/` — 自动生成的 API 客户端 |
| 内置排除 | `__generated__/` — 生成代码目录 |
| 可扩展 | `get-changed-files.sh` 第 3+ 个参数可追加额外排除目录 |

## 影响级别速查

| 级别 | 引用数 | 符号 |
|------|-------|------|
| 高影响 | ≥ 3 | 🔴 |
| 中影响 | 2 | 🟡 |
| 内部文件 | < 2 | ⚖️（跳过分析） |

## 回归优先级速查

优先级按照页面对**用户/业务的核心程度**划分，因项目而异：

| 优先级 | 参考标准 | 典型示例 |
|-------|---------|----------|
| P0 | 主流程页面，直接影响核心业务（下单、支付、登录、结算） | 订单、支付、认证 |
| P1 | 重要辅助功能，影响运营效率但不阻断主流程 | 管理后台、报表、通知 |
| P2 | 低频/边缘功能，影响范围小 | 系统设置、打印、日志 |

## 路由映射说明

**菜单路径推断优先级**（由高到低）：

1. 路由菜单标题字段含中文 → 直接使用（React 项目为 `crumbs`，Vue 项目为 `meta.title`，详见对应指南）
2. `src/app.json` 中对应 `path` 的 `title`（自动探测）
3. 路由无中文标题 → 读取 `component` 组件文件提取标题（组件标题回退）
4. 路由 path 分段兜底（供人工审核）

**需要人工确认的情况**：
- 子流程路由：从另一页面跳入，菜单归属与文件目录不一致
- 多入口路由：可从多个菜单触达同一页面

## 报告输出文件

分析完成后，报告**必须写入项目根目录的 `CHANGE_IMPACT_REPORT.html`**，不能仅在对话中输出文本。文件已存在时覆盖。

## 支持的文件类型

| 扩展名 | 框架 | 解析方式 |
|--------|------|---------|
| `.ts` | 通用 | TypeScript AST |
| `.tsx` | React | TypeScript AST (JSX) |
| `.js` | 通用 | TypeScript AST (JS) |
| `.jsx` | React | TypeScript AST (JSX) |
| `.vue` | Vue | @vue/compiler-sfc + TypeScript AST |
| `.svelte` | Svelte | 文本解析（基础支持） |

