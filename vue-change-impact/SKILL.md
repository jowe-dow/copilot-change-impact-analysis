---
name: vue-change-impact
version: 1.0.0
description: Vue 项目的变更影响分析技能。基于 change-impact-analysis 基础技能，提供 Vue 项目专用的路由解析规则（meta.title 字段、children、meta.hidden 等）和标题回退机制。当检测到项目 package.json 含 vue 依赖时使用本技能。
---

# Vue 变更影响分析

## 前置依赖

> ⚠️ **必须先读取基础技能** [change-impact-analysis/SKILL.md](../change-impact-analysis/SKILL.md)，获取通用分析流程、报告模板、脚本用法和自定义配置规范，再继续阅读本文档获取 Vue 专用的路由解析规则。

## 适用项目

读取项目根目录的 `package.json`，检查 `dependencies` 和 `devDependencies`，满足以下**任一**条件即使用本技能：

| 条件 | 判定结果 |
|------|---------|
| 含 `vue` 且不含 `react` | **Vue 项目** |
| 存在 `.vue` 单文件组件 | **Vue 项目** |
| 路由文件使用 `vue-router` 的 `createRouter` / `new Router` | **Vue 项目** |

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

Vue 项目中，路由配置使用 `vue-router` 的标准结构，标题存储在 `meta.title` 中：

```typescript
// src/router/modules/user.ts
const userRoutes: RouteRecordRaw[] = [
  {
    path: '/user',
    component: Layout,
    meta: { title: '用户管理' },    // ← 一级菜单标题
    children: [
      {
        path: 'list',
        component: () => import('@/views/user/list.vue'),
        meta: { title: '用户列表' },  // ← 二级菜单标题
      },
      {
        path: 'role',
        component: () => import('@/views/user/role.vue'),
        meta: { title: '角色管理' },
      },
    ],
  },
]
```

### RouteRecordRaw 关键字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `path` | `string` | 路由路径 |
| `meta.title` | `string` | **菜单标题**，是确定菜单路径的核心字段 |
| `meta.icon` | `string` | 菜单图标 |
| `meta.hidden` | `boolean` | 是否在菜单中隐藏 |
| `meta.breadcrumb` | `boolean` | 是否显示面包屑 |
| `component` | `Component` | 页面组件 |
| `children` | `RouteRecordRaw[]` | 子路由 |
| `redirect` | `string` | 重定向路径 |
| `name` | `string` | 路由名称（通常为英文，不作为菜单名） |

## 菜单路径提取规则

### 核心：`meta.title` 字段优先

Vue 项目的菜单标题**从路由配置的 `meta.title` 字段获取**。

### 路径拼接规则

嵌套路由的菜单路径通过 `meta.title` 逐级拼接，拼接顺序为**从顶级到当前级** ` > ` 分隔：

```
/user/list → 用户管理 > 用户列表
/system/role/permission → 系统管理 > 角色管理 > 权限设置
```

## 标题回退机制

当路由 `meta.title` 缺失或不含中文时，按以下优先级查找标题：

| 优先级 | 来源 | 示例 |
|-------|------|------|
| 1 | 路由 `meta.title`（含中文时直接使用） | `meta: { title: '用户管理' }` |
| 2 | `defineOptions({ name })` / `export default { name }` | `defineOptions({ name: '用户管理' })` |
| 3 | `useHead` / `useSeoMeta` / `useTitle` | `useHead({ title: '设置' })` |
| 4 | 导航/页头组件的 `title` 属性 | `<van-nav-bar title="订单" />` `<PageHeader title="设置" />` |
| 5 | 顶层标题常量 | `const pageTitle = '订单列表'` |
| 6 | `document.title` 赋值 | `document.title = '首页'` |
| 7 | `<title>` 标签 | `<title>登录</title>` |
| 8 | 第一个 `<h1>` / `<h2>` 纯文本 | `<h1>数据看板</h1>` |

> 以上来源**均只提取含中文字符的结果**，避免英文组件名被误用为菜单名称。

## 路由文件发现方式

### 模块化路由（常见模式）

路由按功能模块拆分到多个文件中：

```
src/router/
├── index.ts              # 主入口，创建 Router 实例
├── modules/
│   ├── user.ts           # 用户管理路由
│   ├── order.ts          # 订单管理路由
│   └── setting.ts        # 系统设置路由
└── guard.ts              # 路由守卫
```

**扫描路径**：`src/router/modules/*.{ts,js}` 或 `src/router/*.{ts,js}`

### 集中式路由

所有路由在单一文件中定义：

**扫描路径**：`src/router/index.{ts,js}` 或 `src/router/routes.{ts,js}`

## 特殊路由处理

### 隐藏路由

```typescript
{
  path: '/user/detail/:id',
  meta: { title: '用户详情', hidden: true },
  component: () => import('@/views/user/detail.vue')
}
```
`meta.hidden = true` 的路由不在侧边菜单中显示，但仍有页面标题。报告中应标注为子流程路由。

### 重定向路由

```typescript
{ path: '/user', redirect: '/user/list' }
```
跳过，不生成菜单映射。

### 动态路由

```typescript
{ path: '/user/:id', meta: { title: '用户详情' } }
```
保留 `meta.title` 作为菜单名，路径参数部分忽略。

## 搜索菜单入口的方法

当自动推断不准时，可在代码中搜索以下模式确认实际入口：

| 搜索目标 | 代码模式 |
|---------|---------|
| 编程式导航 | `router.push('/path')` / `$router.push('/path')` / `useRouter()` |
| 声明式导航 | `<router-link to="/path">` / `<RouterLink to="/path">` |
| 菜单配置 | 搜索 `Menu`、`el-menu`、`a-menu`、`van-tabbar` 组件 |

## 注意事项

- ❌ **不要用 `crumbs` 字段** — 这是特定 React 项目的自定义约定，Vue 项目不使用
- ❌ **不要把路由 `name` 当作菜单名** — `name` 通常是英文标识符，不是显示名称
- ✅ **优先用 `meta.title`** — 这是 Vue-Router 项目的标准菜单标题字段
- ✅ 注意 `meta.hidden` — 隐藏路由不出现在菜单中，属于子流程路由
- ✅ 注意 `children` 字段 — Vue-Router 用 `children` 而非 `routes` 表示子路由
