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

| 级别 | 含义 | 符号 | 回归策略 |
|------|------|------|---------|
| P0 | 入口阻断 / 核心功能阻断 | 🔴 | 立即回归，阻塞发布 |
| P1 | 重要功能受影响 | 🟠 | 发布前必须回归 |
| P2 | 非重要功能受影响 | 🟡 | 可安排回归，不阻塞发布 |
| P3 | 其他 / 不在等级表中 | ⚪ | 低优先级，可观察 |
| 内部文件 | 引用数 < 2 | ⚖️ | 跳过分析 |

> ⚠️ 影响等级以 **faultRating 表** 中的登记等级为准，不再使用引用数量评分。功能不在表中时默认 **P3**。
> - React 项目：[resources/faultRating-react.md](../resources/faultRating-react.md)
> - Vue 项目：[resources/faultRating-vue.md](../resources/faultRating-vue.md)

## 回归优先级速查

| 优先级 | 参考标准 | 典型示例 |
|-------|---------|----------|
| P0 | 主流程页面/入口阻断（登录、下单、支付、核心列表打不开） | 订单、支付、认证、核心列表 |
| P1 | 重要辅助功能，影响运营效率但不阻断主流程 | 管理后台、报表、通知 |
| P2 | 低频/边缘功能，影响范围小 | 系统设置、打印、日志 |
| P3 | 其他（不在 faultRating 表中） | 电子合同等 |

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

