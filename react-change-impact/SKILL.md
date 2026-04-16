---
name: react-change-impact
version: 1.0.0
description: React/Next 项目的变更影响分析技能。基于 change-impact-analysis 基础技能，提供 React 项目专用的路由解析规则（crumbs 字段、isNoNeedSplit、keepAliveKey 等）和标题回退机制。当检测到项目 package.json 含 react 或 react-dom 依赖时使用本技能。
---

# React 变更影响分析

## 前置依赖

> ⚠️ **必须先读取基础技能** [change-impact-analysis/SKILL.md](../change-impact-analysis/SKILL.md)，获取通用分析流程、报告模板、脚本用法和自定义配置规范，再继续阅读本文档获取 React 专用的路由解析规则。

## 适用项目

读取项目根目录的 `package.json`，检查 `dependencies` 和 `devDependencies`，满足以下**任一**条件即使用本技能：

| 条件 | 判定结果 |
|------|---------|
| 含 `react` 或 `react-dom` | **React 项目** |
| 含 `next` 且含 `react` | **Next (React) 项目** |
| 存在 `.tsx` / `.jsx` 入口文件（如 `src/main.tsx`、`src/app.tsx`） | **React 项目** |
| 路由文件使用 `react-router-dom` 相关 API | **React 项目** |

## 影响分级

> ⚠️ **必须先读取 faultRating 表** [resources/faultRating.md](./resources/faultRating.md)，在分析各变更文件影响的菜单/功能后，依据该表评定影响等级。

| 等级 | 含义 | 回归策略 |
|------|------|----------|
| 🔴 P0 | 入口阻断 / 核心功能阻断 | 立即回归，阻塞发布 |
| 🟠 P1 | 重要功能受影响 | 发布前必须回归 |
| 🟡 P2 | 非重要功能受影响 | 可安排回归，不阻塞发布 |
| ⚪ P3 | 其他 / 不在等级表中 | 低优先级，可观察 |

**评级规则**：在 `resources/faultRating.md` 的功能等级列表中匹配受影响菜单/功能，取对应等级；若功能不在表中，默认评定为 **P3**。

## 路由配置结构

### 典型路由文件格式

React 项目中，路由配置通常是一个 `IRoute[]` 数组，路由文件分布在各页面目录下（如 `src/pages/*/routes.ts`），由主路由文件统一聚合。

```typescript
// src/pages/student/routes.ts
const studentRoutes: IRoute[] = [
  {
    path: '/student',
    crumbs: '教务中心',         // ← 一级菜单标题
    routes: [
      { path: '.', redirect: 'list' },
      {
        path: 'list',
        component: '@/pages/student/list/index',
        crumbs: '学员管理',     // ← 二级菜单标题
      },
    ],
  },
]
```

### IRoute 关键字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `path` | `string` | 路由路径，支持相对路径（自动拼接父级） |
| `crumbs` | `string \| string[]` | **菜单/面包屑标题**（中文），是确定菜单路径的核心字段 |
| `isNoNeedSplit` | `boolean` | `true` 时不与上级 crumbs 拼接，独立展示 |
| `component` | `string` | 页面组件路径，`@/` 映射到 `src/` |
| `routes` | `IRoute[]` | 子路由 |
| `redirect` | `string` | 重定向路径 |
| `authCode` | `string[]` | 权限码 |
| `layout` | `string` | 布局类型（`workbench` / `fullscreen` 等） |
| `keepAliveKey` | `string` | Tab 页缓存标识，共享同一 key 的路由视为同一 Tab |

## 菜单路径提取规则

### 核心：`crumbs` 字段优先

React 项目的菜单标题**直接从路由配置的 `crumbs` 字段获取**，而非 `meta.title`。

### 路径拼接规则

嵌套路由的菜单路径通过 `crumbs` 逐级拼接，拼接顺序为**从顶级到当前级** ` > ` 分隔：

```
/student/list → 教务中心 > 学员管理
/setting/teaching/lessonSetting → 业务设置 > 教务设置 > 课程设置
/schedule/table/my-table → 教务中心 > 课表 > 我的课表
```

### `crumbs` 为数组时

数组格式会用 `·` 连接作为当前级显示名，但在报告中应拆解为实际含义：

```typescript
crumbs: ['意向学员', '招生中心'],
isNoNeedSplit: true  // 不与父级拼接
// 菜单路径 → 招生中心 > 意向学员
```

### `isNoNeedSplit: true` 时

该路由的 crumbs 不与父级拼接，独立作为顶级入口。此时需要从 crumbs 数组本身提取完整的层级关系。

## 标题回退机制

当路由未配置 `crumbs` 或 `crumbs` 中不含中文时，按以下优先级查找标题：

| 优先级 | 来源 | 示例 |
|-------|------|------|
| 1 | 路由 `crumbs` 字段（含中文时直接使用） | `crumbs: '学员管理'` |
| 2 | 组件文件中的页头标题属性 | `<PageHeader title="课程商品" />` |
| 3 | 组件文件中的顶层标题常量 | `const pageTitle = '订单列表'` |
| 4 | `document.title` 赋值 | `document.title = '首页'` |
| 5 | JSX 中第一个含中文的 `<h1>` / `<h2>` | `<h1>数据看板</h1>` |

> ⚠️ React 项目**不使用** `meta.title`、`defineOptions`、`useHead` 等 Vue 特有 API。

## 路由文件发现方式

### 分散式路由（常见模式）

路由文件分布在各页面目录下，由主入口通过 glob 聚合：

```typescript
// src/routes/index.ts
const routeModules = import.meta.glob(
  ['../pages/**/route.{ts,tsx}', '../pages/**/routes.{ts,tsx}'],
  { eager: true, import: 'default' }
)
```

**扫描路径**：`src/pages/**/routes.{ts,tsx}` 或 `src/pages/**/route.{ts,tsx}`

### 集中式路由

所有路由定义在单一文件中（如 `src/routes/config.ts`）。

**扫描路径**：`src/routes/*.{ts,tsx}`

## 特殊路由处理

### 重定向路由

```typescript
{ path: '.', redirect: 'list' }
```
跳过，不生成菜单映射。

### 通配路由

```typescript
{ path: '*', component: '@/pages/404/index' }
```
跳过，不生成菜单映射。

### 共享 keepAliveKey 的 Tab 路由

多个路由共享同一 `keepAliveKey`，表示它们是同一页面的不同 Tab：

```typescript
{
  path: 'table',
  crumbs: '课表',
  component: '@/pages/schedule/table/index',
  routes: [
    { keepAliveKey: 'schedule/table', crumbs: '我的课表', path: 'my-table', isSameTabKey: true },
    { keepAliveKey: 'schedule/table', crumbs: '时间课表', path: 'timetable', isSameTabKey: true },
  ]
}
```

在报告中，这些 Tab 路由的菜单路径应完整到 Tab 级别：
- `教务中心 > 课表 > 我的课表`
- `教务中心 > 课表 > 时间课表`

## 搜索菜单入口的方法

当自动推断不准时，可在代码中搜索以下模式确认实际入口：

| 搜索目标 | 代码模式 |
|---------|---------|
| 路由跳转 | `history.push('/path')` / `navigate('/path')` / `useNavigate()` |
| 链接组件 | `<Link to="/path">` / `<NavLink to="/path">` |
| 编程式导航 | `window.location.href` / `router.push` |
| 菜单渲染 | 搜索 `Menu`、`Sider`、`Nav` 组件中引用的路由 path |

## 注意事项

- ❌ **不要用 `meta.title`** — 这是 Vue-Router 的约定，React 项目不使用
- ❌ **不要用 `defineOptions`** — 这是 Vue 3 `<script setup>` 的 API
- ❌ **不要用 `useHead` / `useSeoMeta`** — 这是 Nuxt/Vue 的组合式 API
- ✅ **优先用 `crumbs` 字段** — 这是 React 项目路由的标准菜单标题字段
- ✅ 注意 `isNoNeedSplit` — 标记为 `true` 的路由不拼接父级
- ✅ 注意 crumbs 数组格式 — `['A', 'B']` 代表 `A·B`，需按语义拆解层级
