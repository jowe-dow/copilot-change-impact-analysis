---
name: change-impact-analysis
version: 4.0.0
description: 前端项目变更影响分析统一技能。自动检测项目框架（React/Vue），解析路由配置生成路由-菜单映射表，结合 git diff 获取变更文件，分析变更代码的引用关系、触发位置与业务影响面，输出可供测试回归的影响分析报告（含菜单路径、触发路径、回归优先级）。
---

# 🔍 Change Impact Analysis — 变更影响分析

## 概述 (Overview) 📋

对当前分支与基准分支（默认 master）的变更进行静态分析，输出「变更文件 → 引用位置 → 菜单路径 → 回归建议」完整链路报告。
本技能**自动检测项目框架类型**（React / Vue），并使用对应的路由解析规则完成分析。

## 技能目标 (Objectives)

- 自动检测项目类型（React 或 Vue）。
- 自动解析路由配置生成 `path → 菜单路径` 映射表（与具体目录结构无关）。
- 路由标题缺失或不含中文时，**自动读取 component 组件文件提取页面标题**（组件标题回退）。
- 通过 git diff 获取变更文件并过滤分析范围。
- 分析变更代码的触发位置与业务影响面，输出可供 QA 直接使用的回归报告。

## 使用场景

- **PR/MR 提交前影响评估**：分析当前分支改了什么、影响哪些页面，生成可粘贴到 PR 描述的报告。
- **QA 回归策略制定**：输出按优先级排序的回归建议表，测试人员无需看代码即可理解。
- **路由-菜单映射表生成**：独立生成项目的 `path → 菜单路径` 映射表。

---

## 触发方式

用户只需说一句话即可启动完整分析流程，示例：

- “分析当前分支变更，生成回归测试报告”
- “帮我做变更影响分析”
- “生成 CHANGE_IMPACT_REPORT”
- “分析这个项目的变更影响，输出 HTML 报告”

触发后 AI 自动执行：检测项目框架 → 运行 git diff 脚本 → 解析路由与菜单映射 → 分析引用关系 → 查 faultRating 评级 → 读模板生成报告 → 写入 `CHANGE_IMPACT_REPORT.html`。

---

## 项目类型自动检测

读取项目根目录的 `package.json`，检查 `dependencies` 和 `devDependencies`，**从上到下逐条匹配，命中第一条即停止判定**：

| 条件 | 判定结果 | 使用规则 |
|------|---------|---------|
| 含 `react` 或 `react-dom` | **React 项目** | 使用「React 路由规则」 |
| 含 `next` 且含 `react` | **React 项目** | 使用「React 路由规则」 |
| 存在 `.tsx` / `.jsx` 入口文件 | **React 项目** | 使用「React 路由规则」 |
| 路由文件使用 `react-router-dom` | **React 项目** | 使用「React 路由规则」 |
| 含 `vue` 且不含 `react` | **Vue 项目** | 使用「Vue 路由规则」 |
| 存在 `.vue` 单文件组件 | **Vue 项目** | 使用「Vue 路由规则」 |
| 路由文件使用 `vue-router` | **Vue 项目** | 使用「Vue 路由规则」 |

---

## 使用流程 (Usage)

1. **检测项目类型**：读取 `package.json` 判定 React 或 Vue。
2. **运行脚本获取变更文件**：
   ```bash
   bash <skill-dir>/scripts/get-changed-files.sh master
   ```
   > `<skill-dir>` 为本技能所在目录（如 `.github/skills/change-impact-analysis/`、`.copilot/skills/change-impact-analysis/` 或 `npx skills add` 安装的路径），AI 需根据实际安装位置自动替换。
3. **读取项目路由文件**，按对应框架的规则（见下方「路由解析规则」）提取路由树与菜单标题。
4. **分析引用关系**：在 `src/` 中搜索各变更文件的引用位置，跳过引用数 < 2 的文件。
5. **关联路由与评级**：关联引用文件到路由确定菜单路径，查阅对应的 faultRating 表评定影响等级（P0/P1/P2/P3）；若功能不在表中，默认评为 **P3**。
   - React 项目：[resources/faultRating-react.md](./resources/faultRating-react.md)
   - Vue 项目：[resources/faultRating-vue.md](./resources/faultRating-vue.md)
6. **生成报告**：**先完整读取 [ReportTemplate.html](./resources/ReportTemplate.html)**，然后严格按模板的 HTML/CSS/JS 结构生成报告，仅替换占位符和填充动态数据区块，**写入项目根目录 `CHANGE_IMPACT_REPORT.html`**（若已存在则覆盖）。详见下方「报告 HTML 结构严格规范」。

## 输入规范 (Input)

- 基准分支名（默认 `master`）。
- 项目根目录路径。
- 可选：指定变更文件列表（跳过 git diff）。

## 输出规范 (Output)

- **`CHANGE_IMPACT_REPORT.html`**（项目根目录）— 变更影响分析报告。分析完成后**必须将报告写入此文件**，不能仅在对话中输出文本。
- ⚠️ **强制要求：报告 HTML 必须严格按照 [ReportTemplate.html](./resources/ReportTemplate.html) 1:1 还原**，包括完整的 `<style>` 块、所有 CSS 变量、每个 HTML 元素的 class 名称、嵌套层级、`<script>` 块。**不得自创样式、不得省略任何 CSS 规则、不得改变 HTML 结构层级**。详见下方「报告 HTML 结构严格规范」章节。

---

## 路由解析规则

> ⚠️ **根据项目类型检测结果，选择对应的路由规则节。React 和 Vue 的路由字段完全不同，严禁混用。**

### React 项目路由规则

> ⚠️ 本节仅适用于 React / Next 项目。Vue 项目请跳过本节。

#### 路由配置结构

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

#### IRoute 关键字段

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

#### 菜单路径提取

- **核心**：`crumbs` 字段优先。React 项目的菜单标题**直接从路由配置的 `crumbs` 字段获取**，而非 `meta.title`。
- **拼接规则**：嵌套路由的菜单路径通过 `crumbs` 逐级拼接，从顶级到当前级用 ` > ` 分隔：
  ```
  /student/list → 教务中心 > 学员管理
  /setting/teaching/lessonSetting → 业务设置 > 教务设置 > 课程设置
  ```
- **`crumbs` 为数组时**：数组格式 `['意向学员', '招生中心']` 在报告中应拆解为实际层级含义。
- **`isNoNeedSplit: true` 时**：该路由的 crumbs 不与父级拼接，独立作为顶级入口。

#### 路由文件发现

**分散式路由（常见）**：`src/pages/**/routes.{ts,tsx}` 或 `src/pages/**/route.{ts,tsx}`

```typescript
// src/routes/index.ts
const routeModules = import.meta.glob(
  ['../pages/**/route.{ts,tsx}', '../pages/**/routes.{ts,tsx}'],
  { eager: true, import: 'default' }
)
```

**集中式路由**：`src/routes/*.{ts,tsx}`

#### React 特殊路由处理

- **重定向路由** `{ path: '.', redirect: 'list' }` → 跳过
- **通配路由** `{ path: '*', component: '@/pages/404/index' }` → 跳过
- **共享 keepAliveKey 的 Tab 路由**：多个路由共享同一 `keepAliveKey`，菜单路径应完整到 Tab 级别

#### React 搜索菜单入口的方法

| 搜索目标 | 代码模式 |
|---------|---------|
| 路由跳转 | `history.push('/path')` / `navigate('/path')` / `useNavigate()` |
| 链接组件 | `<Link to="/path">` / `<NavLink to="/path">` |
| 编程式导航 | `window.location.href` / `router.push` |
| 菜单渲染 | 搜索 `Menu`、`Sider`、`Nav` 组件中引用的路由 path |

---

### Vue 项目路由规则

> ⚠️ 本节仅适用于 Vue 项目。React 项目请跳过本节。

#### 路由配置结构

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

#### RouteRecordRaw 关键字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `path` | `string` | 路由路径 |
| `meta.title` | `string` | **菜单标题**，是确定菜单路径的核心字段 |
| `meta.icon` | `string` | 菜单图标 |
| `meta.hidden` | `boolean` | 是否在菜单中隐藏 |
| `meta.breadcrumb` | `boolean` | 是否显示面包屑 |
| `component` | `Component` | 页面组件 |
| `children` | `RouteRecordRaw[]` | 子路由（注意：Vue 用 `children`，不是 `routes`） |
| `redirect` | `string` | 重定向路径 |
| `name` | `string` | 路由名称（通常为英文，不作为菜单名） |

#### 菜单路径提取

- **核心**：`meta.title` 字段优先。Vue 项目的菜单标题**从路由配置的 `meta.title` 字段获取**。
- **拼接规则**：嵌套路由的菜单路径通过 `meta.title` 逐级拼接，从顶级到当前级用 ` > ` 分隔：
  ```
  /user/list → 用户管理 > 用户列表
  /system/role/permission → 系统管理 > 角色管理 > 权限设置
  ```

#### 路由文件发现

**模块化路由（常见）**：`src/router/modules/*.{ts,js}` 或 `src/router/*.{ts,js}`

**集中式路由**：`src/router/index.{ts,js}` 或 `src/router/routes.{ts,js}`

#### Vue 特殊路由处理

- **隐藏路由** `meta.hidden = true` → 不在侧边菜单显示，报告中标注为子流程路由
- **重定向路由** `{ path: '/user', redirect: '/user/list' }` → 跳过
- **动态路由** `{ path: '/user/:id' }` → 保留 `meta.title`，忽略路径参数

#### Vue 搜索菜单入口的方法

| 搜索目标 | 代码模式 |
|---------|---------|
| 编程式导航 | `router.push('/path')` / `$router.push('/path')` / `useRouter()` |
| 声明式导航 | `<router-link to="/path">` / `<RouterLink to="/path">` |
| 菜单配置 | 搜索 `Menu`、`el-menu`、`a-menu`、`van-tabbar` 组件 |

---

## 标题回退机制

当路由的菜单标题字段缺失或不含中文时，需按**项目类型**使用不同的回退策略。

### 通用原则

- 所有来源**均只提取含中文字符的结果**，避免英文组件名被误用为菜单名称。
- 不同框架的标题字段、回退 API 完全不同，**严禁混用**。

### 标题解析通用优先级

1. 路由菜单标题字段（React: `crumbs` / Vue: `meta.title`，含中文时使用）
2. `src/app.json` 中对应 `path` 的 `title`（脚本自动探测）
3. 组件文件标题回退（详见下方各框架回退链）
4. 路径分段兜底（仅供人工审核，**生产报告中必须替换为中文**）

### React 标题回退链

> ⚠️ 仅适用于 React 项目

| 优先级 | 来源 | 示例 |
|-------|------|------|
| 1 | 路由 `crumbs` 字段（含中文时直接使用） | `crumbs: '学员管理'` |
| 2 | 组件文件中的页头标题属性 | `<PageHeader title="课程商品" />` |
| 3 | 组件文件中的顶层标题常量 | `const pageTitle = '订单列表'` |
| 4 | `document.title` 赋值 | `document.title = '首页'` |
| 5 | JSX 中第一个含中文的 `<h1>` / `<h2>` | `<h1>数据看板</h1>` |

### Vue 标题回退链

> ⚠️ 仅适用于 Vue 项目

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

---

## 菜单路径判断方法

### 菜单路径格式规范

- ✅ 必须使用**用户在 App/网站中实际看到的菜单名称**
- ✅ 层级之间用 ` > ` 分隔，如 `一级菜单 > 二级菜单 > 三级菜单`
- ❌ **不能用英文文件夹名/路由 path 段直译**（如 `setting > scheduleSet`）
- ❌ **不能用代码变量名**（如 `ScheduleSet`、`OrderCheck`）
- 如果某个路由找不到中文标题 → 查看引用该路由的页面/菜单列表组件，确认真实入口名称

### 确认方法

**正确方法**：在代码中搜索「谁在调用这个路由 path」，确认用户实际从哪个业务流程触达这个页面（具体搜索模式见上方各框架的「搜索菜单入口的方法」）。

当自动推断不准确时，可以进一步排查：
1. 如项目有统一菜单/设置列表页，读取其模板中的分区标题和菜单项标题来确定真实层级
2. 如项目有页面注册表（`app.json` 等），优先使用其中的 `title` 字段

### 三类路由

| 类型 | 定义 | 菜单路径取法 |
|------|------|------------|
| 直达菜单路由 | 用户点导航栏/菜单直接进入 | 该菜单项本身 |
| 子流程路由 | 由另一页面跳入，非独立入口 | 触发入口所在菜单（需人工确认后在报告中标注） |
| 多入口路由 | 可从多个菜单触达 | 列出所有入口，如 `多入口（A / B / C）` |

---

## 影响分级说明 (Impact Rating)

变更影响等级由**受影响功能在 faultRating 表中的登记等级**决定，不再使用引用次数评估。

| 等级 | 含义 | 回归策略 |
|------|------|----------|
| 🔴 P0 | 入口阻断 / 核心功能阻断 | 立即回归，阻塞发布 |
| 🟠 P1 | 重要功能受影响 | 发布前必须回归 |
| 🟡 P2 | 非重要功能受影响 | 可安排回归，不阻塞发布 |
| ⚪ P3 | 其他 / 不在等级表中 | 低优先级，可观察 |

### 评级步骤

1. 通过路由关联确定变更文件影响的菜单/功能
2. 根据项目类型读取对应的 faultRating 表，在功能等级列表中查找该功能
   - React 项目：[resources/faultRating-react.md](./resources/faultRating-react.md)
   - Vue 项目：[resources/faultRating-vue.md](./resources/faultRating-vue.md)
3. 取匹配行的等级列作为影响等级
4. **若功能不在 faultRating 表中，默认评定为 P3**

---

## 关键规范速查

- 路由映射只关心 `path` → 菜单路径，与文件目录无关。
- 若路由菜单标题字段缺失或无中文 → 按对应框架的标题回退机制依次查找，**绝不用路径段直译**。
- 影响分级：引用次数 < 2 的变更文件不纳入分析，基于受影响功能在 faultRating 表中的等级（P0/P1/P2/P3）；功能不在表中时默认给 **P3**。
- 业务触发路径必须用**中文业务语言**描述（用户操作步骤，非代码路径）。

## 最佳实践 (Best Practices)

- 对共享组件（`src/common/`、`src/components/`、`src/shared/`）重点关注引用面，共享组件变更可能同时影响多个功能，需逐一查表评级。
- 报告中的触发操作用用户操作步骤描述，非代码逻辑。

---

## 框架专用 API 防混用对照表 ⚠️

| API / 字段 | React 项目 | Vue 项目 |
|------------|-----------|---------|
| `crumbs` | ✅ 核心菜单标题字段 | ❌ 不存在 |
| `meta.title` | ❌ 不使用 | ✅ 核心菜单标题字段 |
| `routes`（子路由字段名） | ✅ 使用 `routes` | ❌ 使用 `children` |
| `children`（子路由字段名） | ❌ 不使用 | ✅ 使用 `children` |
| `isNoNeedSplit` | ✅ 独立入口标记 | ❌ 不存在 |
| `keepAliveKey` | ✅ Tab 页缓存标识 | ❌ 不存在 |
| `meta.hidden` | ❌ 不使用 | ✅ 菜单隐藏标记 |
| `defineOptions` | ❌ Vue 专属 API | ✅ Vue 3 script setup |
| `useHead` / `useSeoMeta` | ❌ Nuxt/Vue 专属 | ✅ 可用于标题回退 |
| `<PageHeader title>` | ✅ 可用于标题回退 | ✅ 可用于标题回退 |
| `history.push` / `navigate` | ✅ React 导航 | ❌ 不使用 |
| `router.push` / `$router.push` | ❌ 不使用 | ✅ Vue 导航 |
| `<Link to>` / `<NavLink to>` | ✅ React 链接 | ❌ 不使用 |
| `<router-link to>` | ❌ 不使用 | ✅ Vue 链接 |

---

## 报告 HTML 结构严格规范 ⚠️

> **核心原则：生成报告前必须先读取 [ReportTemplate.html](./resources/ReportTemplate.html)，输出的 HTML 必须与模板 1:1 一致。不得自创样式、不得省略 CSS、不得改变 HTML 层级结构。**

### 生成流程（强制）

1. **先读取模板**：生成报告前 **必须** 使用 `read_file` 完整读取 `resources/ReportTemplate.html`
2. **复制静态部分**：将模板中的 `<style>` 块、`<script>` 块、header、sidebar、stats 等静态骨架**原样复制**到输出文件
3. **仅替换动态内容**：只替换占位符和重复区块中的数据，**不改动任何 HTML 标签、class 名、嵌套结构**
4. **写入文件**：将完整 HTML 写入 `CHANGE_IMPACT_REPORT.html`

### 必须原样复制的静态部分

以下内容必须**逐字复制**，不得修改、简化或省略：

| 部分 | 说明 |
|------|------|
| `<style>` 块（整个 CSS） | 包含所有 CSS 变量（`:root`）、所有选择器、媒体查询、动画。**一个字都不能改** |
| `<script>` 块（整个 JS） | 包含 `buildNav()`、`scrollspy()`、`toggleSection()`、`toggleCard()`、`toggleRefList()` 以及自动样式脚本。**原样复制** |
| `.header` 整个头部结构 | 包括 `header-inner`、`header-top`、`header-brand`、`header-logo`、`header-titles`、`header-status`、`header-divider`、`.meta` 等所有嵌套元素 |
| `.sidebar` 侧边栏 | `nav-box` + `nav-box-hd` + `<ul id="navTree">`（内容由 JS 自动生成，保留空 `<ul>`） |
| `.legend` 图例栏 | section3 底部的优先级图例，四个 badge 说明 |

### 占位符替换规则

模板中使用 `{PLACEHOLDER}` 形式的占位符，生成时替换为实际数据：

| 占位符 | 替换为 |
|--------|--------|
| `{BRANCH_NAME}` | 当前分支名 |
| `{BASE_BRANCH}` | 基准分支名（默认 `master`） |
| `{TIMESTAMP}` | 生成日期 `YYYY-MM-DD` |
| `{TOTAL_FILES}` | 变更文件总数（纳入分析的） |
| `{HIGH_COUNT}` | P0 级文件数 |
| `{MID_COUNT}` | P1 级文件数 |

### HTML 结构层级（必须严格遵循）

```
<body>
├── .header                              ← 原样复制，仅替换占位符
│   └── .header-inner
│       ├── .header-top
│       │   ├── .header-brand > .header-logo + .header-titles
│       │   └── .header-status
│       ├── .header-divider
│       └── .meta > .meta-item × N
│
├── .page-body                           ← 左右布局容器
│   ├── aside.sidebar                    ← 原样复制（JS 自动生成导航）
│   │   └── .nav-box > .nav-box-hd + ul#navTree
│   │
│   └── main.main-content
│       ├── .notes#summary               ← 回归总结说明
│       ├── .stats                        ← 统计卡片（原样复制，替换占位符）
│       │   ├── .stat-card.total
│       │   ├── .stat-card.high
│       │   └── .stat-card.mid
│       │
│       ├── .section#section1             ← 变更文件总览
│       │   ├── .section-title.collapsible.collapsed
│       │   └── .section-body.collapsed
│       │       └── .module-group × N     ← 【动态重复】每个模块一个
│       │
│       ├── .section#section2             ← 功能维度
│       │   ├── .section-title
│       │   └── .detail-card × N          ← 【动态重复】每个变更文件一个
│       │
│       └── .section#section3             ← 业务维度(测试回归建议)
│           ├── .section-title
│           ├── .regression-group × N     ← 【动态重复】每个回归分组一个
│           └── .legend                   ← 原样复制
│
└── <script>                             ← 原样复制
```

### 动态重复区块详细结构

以下三个区块需要根据实际分析数据 **重复生成**，但每次重复 **必须严格使用模板中定义的 HTML 结构和 class 名**。

#### ① module-group（Section 1 中每个模块）

```html
<div class="module-group" id="module-{模块英文短名}">
  <h3 class="module-heading">
    {模块中文名}
    <span class="mod-badge">{N} 个文件</span>
  </h3>
  <div class="module-table-wrap">
    <table>
      <thead>
        <tr>
          <th style="width:36px">#</th>
          <th>变更文件</th>
          <th style="width:60px">优先级</th>
          <th>影响功能范围</th>
        </tr>
      </thead>
      <tbody>
        <!-- 每个变更文件一行 -->
        <tr>
          <td>{序号}</td>
          <td><code>{文件完整路径}</code></td>
          <td><span class="badge badge-p{N}">P{N}</span></td>
          <td>{受影响的菜单路径，多个用分号分隔}</td>
        </tr>
      </tbody>
    </table>
  </div>
</div>
```

#### ② detail-card（Section 2 中每个变更文件）

```html
<div class="detail-card impact-p{N}" id="file-{文件短名去扩展名}">
  <div class="detail-header" onclick="toggleCard(this)">
    <span class="arrow open">▶</span>
    <span class="badge badge-p{N}">{等级emoji} P{N}</span>
    <div class="file-path">
      <span class="file-name">{文件名}</span>
      <span class="file-dir">{目录路径}</span>
    </div>
  </div>
  <div class="detail-body">
    <!-- 变更摘要 -->
    <div class="change-summary">
      变更摘要：{简述改了什么}
    </div>

    <!-- 引用位置（可折叠） -->
    <div class="section-label collapsible-label" onclick="toggleRefList(this)">
      <span class="cl-arrow open">▶</span>
      引用位置
    </div>
    <div class="collapsible-content">
      <ul class="ref-list">
        <li><code>{引用文件路径}</code></li>
        <!-- 按实际引用数重复 li -->
      </ul>
    </div>

    <!-- 影响页面 -->
    <h4 class="affected-pages-hd">影响页面</h4>
    <table class="sub-table">
      <thead>
        <tr>
          <th>影响页面</th>
          <th>菜单路径</th>
          <th>业务触发路径</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td>{页面中文名}</td>
          <td class="menu-path">{菜单路径}</td>
          <td><span class="biz-path">{用户操作步骤描述}</span></td>
        </tr>
      </tbody>
    </table>
  </div>
</div>
```

**等级 emoji 映射**：P0 → 🔴，P1 → 🟠，P2 → 🟡，P3 → ⚪

#### ③ regression-group（Section 3 中每个回归分组）

```html
<div class="regression-group" id="regression-{序号}">
  <h3 class="regression-heading">
    <span class="rh-bar"></span>
    {回归范围名称}
  </h3>
  <div class="regression-table-wrap">
    <table>
      <thead>
        <tr>
          <th style="width:60px">优先级</th>
          <th>菜单路径</th>
          <th>触发操作</th>
          <th style="width:160px">关联变更</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><span class="badge badge-p{N}">P{N}</span></td>
          <td class="menu-path">{菜单路径}</td>
          <td><span class="trigger-action">{用户操作步骤}</span></td>
          <td><code>{变更文件短名}</code></td>
        </tr>
      </tbody>
    </table>
  </div>
</div>
```

### Section 1 特殊规则

- `.section-title` 必须带 `collapsible collapsed` 两个 class（默认折叠）
- `.section-body` 必须带 `collapsed` class
- `onclick="toggleSection(this)"` 必须存在于 `.section-title` 上

### 回归总结说明 (.notes#summary) 规则

```html
<div class="notes" id="summary">
  <h3>回归总结说明</h3>
  <ul>
    <li>{要点1：针对本次变更的整体回归重点}</li>
    <li>{要点2：P0/P1 场景风险提示}</li>
    <!-- 按实际情况添加 3-5 条要点 -->
  </ul>
</div>
```

- 必须放在 `.main-content` 最顶部（stats 上方）
- `<h3>` 前面的 📋 emoji 由 CSS `::before` 生成，**不要在 HTML 中写 emoji**
- `<li>` 前面的圆点也由 CSS `::before` 生成，**不要添加任何列表符号**

### 严禁事项 🚫

| 禁止行为 | 说明 |
|----------|------|
| ❌ 自定义 CSS | 不得添加、删除或修改模板中的任何 CSS 规则 |
| ❌ 改变 class 名 | 必须使用模板定义的 class，不得使用自创名称 |
| ❌ 省略 CSS 变量 | `:root` 中的所有变量必须保留 |
| ❌ 内联样式替代 CSS | 不得用 `style=""` 替代模板中的 class 样式（模板中已有的 `style` 属性除外） |
| ❌ 修改 HTML 层级 | 不得改变父子嵌套关系 |
| ❌ 省略 `<script>` | 完整 JS 代码必须在 `</body>` 前原样输出 |
| ❌ 省略 `<style>` | 完整 CSS 必须在 `<head>` 中原样输出 |
| ❌ 修改动画/伪元素 | `@keyframes pulse`、`::before`、`::after` 等不得修改 |
| ❌ 省略 `@media print` | 打印样式必须保留 |
| ❌ 改变 section 的 id 命名 | `#summary`、`#section1`、`#section2`、`#section3` 必须固定 |

### 自检清单（生成报告后验证）

- [ ] `<style>` 块是否与模板**完全一致**（包括注释和空行可省略，但 CSS 规则不能少）
- [ ] `<script>` 块是否与模板**完全一致**
- [ ] Header 结构是否完整（brand + status + divider + meta）
- [ ] Sidebar 空 `<ul id="navTree">` 是否存在
- [ ] `.notes#summary` 是否在 `.stats` 之前
- [ ] Stats 三个卡片（total / high / mid）是否存在
- [ ] Section 1 是否包含 `.module-group` 且有正确的 `id`
- [ ] Section 1 的 `.section-title` 是否有 `collapsible collapsed` class
- [ ] Section 2 每个 `.detail-card` 是否有正确的 `impact-p{N}` class 和 `id`
- [ ] Section 2 每个卡片是否包含 `change-summary` + `ref-list` + `sub-table` 三部分
- [ ] Section 3 每个 `.regression-group` 是否有正确的 `id`
- [ ] Section 3 底部 `.legend` 是否存在
- [ ] 所有 badge 是否使用 `badge-p0/p1/p2/p3` class
- [ ] 所有菜单路径 `<td>` 是否有 `class="menu-path"`
- [ ] 所有触发操作是否包裹在 `<span class="trigger-action">` 中
- [ ] 所有业务触发路径是否包裹在 `<span class="biz-path">` 中

---

## 注意事项 (Precautions)

- ❌ 不要用**文件目录/路由模块名**直接推断菜单路径（同名目录不等于同名菜单）
- ❌ 不要忽略**子流程路由**：从其他页面跳入的路由，菜单路径是「触发入口」所在菜单
- ❌ 不要漏掉**多入口路由**：可从多个菜单触达的页面，要列出所有入口
- ❌ 不要把仅被同目录文件引用的变更标为高影响
- ❌ 路由无中文标题时，**不要直接用路径段作为菜单名**，先按对应框架的回退机制查找
- ❌ **不要输出英文路由段**（如 `enroll > orderCheck`），报告中所有菜单路径必须是中文

## 工具与资源

| 文件 | 用途 |
|------|------|
| [scripts/get-changed-files.sh](./scripts/get-changed-files.sh) | 获取变更文件（可配置排除目录） |
| [scripts/README.md](./scripts/README.md) | 脚本参数说明 |
| [resources/ReportTemplate.html](./resources/ReportTemplate.html) | 报告输出模板（HTML） |
| [resources/faultRating-react.md](./resources/faultRating-react.md) | React 项目功能影响等级表 |
| [resources/faultRating-vue.md](./resources/faultRating-vue.md) | Vue 项目功能影响等级表 |
| [examples/INDEX.md](./examples/INDEX.md) | 示例文档导航 |
