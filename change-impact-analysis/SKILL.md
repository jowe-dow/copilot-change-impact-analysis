---
name: change-impact-analysis
version: 3.0.0
description: 前端项目变更影响分析的基础技能。通过解析路由配置生成路由-菜单映射表，结合 git diff 获取变更文件，分析变更代码的引用关系、触发位置与业务影响面，输出可供测试回归的影响分析报告（含菜单路径、触发路径、回归优先级）。本技能为框架无关的基础能力，需配合对应的框架路由分析技能使用（如 react-change-impact、vue-change-impact）。
---

# 🔍 Change Impact Analysis — 变更影响分析（基础技能）

## 概述 (Overview) 📋

对当前分支与基准分支（默认 master）的变更进行静态分析，输出「变更文件 → 引用位置 → 菜单路径 → 回归建议」完整链路报告。
本技能提供**框架无关的通用分析方法论**（git diff、引用分析、报告模板、自定义配置等），具体的路由解析规则由框架专用技能提供：

| 项目类型 | 配套技能 |
|---------|---------|
| React / Next | `react-change-impact` |
| Vue | `vue-change-impact` |

> ⚠️ 使用时应先读取本基础技能，再读取对应框架技能获取路由解析规则。

## 技能目标 (Objectives)

- 自动解析路由配置生成 `path → 菜单路径` 映射表（与具体目录结构无关）。
- 路由标题缺失或不含中文时，**自动读取 component 组件文件提取页面标题**（组件标题回退）。
- 通过 git diff 获取变更文件并过滤分析范围。
- 分析变更代码的触发位置与业务影响面，输出可供 QA 直接使用的回归报告。

## 使用场景

- **PR/MR 提交前影响评估**：分析当前分支改了什么、影响哪些页面，生成可粘贴到 PR 描述的报告。
- **QA 回归策略制定**：输出按优先级排序的回归建议表，测试人员无需看代码即可理解。
- **路由-菜单映射表生成**：独立生成项目的 `path → 菜单路径` 映射表。

## 使用方法 (Usage)

1. 运行脚本获取变更文件：
   ```bash
   bash .github/skills/change-impact-analysis/scripts/get-changed-files.sh master
   ```
2. 读取项目路由文件，按对应框架技能的规则提取路由树与菜单标题。
3. 在 `src/` 中搜索各变更文件的引用位置，跳过引用数 < 2 的文件。
4. 关联引用文件到路由，确定菜单路径。
5. 对每个受影响的菜单/功能，查阅对应框架的 `resources/faultRating.md`（见下方"影响分级说明"章节），评定影响等级（P0/P1/P2/P3）；若功能不在表中，默认评为 **P3**。
6. **先完整读取 [ReportTemplate.html](./resources/ReportTemplate.html)**，然后严格按模板的 HTML/CSS/JS 结构生成报告，仅替换占位符和填充动态数据区块，**写入项目根目录 `CHANGE_IMPACT_REPORT.html`**（若已存在则覆盖）。详见下方「报告 HTML 结构严格规范」。

## 输入规范 (Input)

- 基准分支名（默认 `master`）。
- 项目根目录路径。
- 可选：指定变更文件列表（跳过 git diff）。

## 输出规范 (Output)

- **`CHANGE_IMPACT_REPORT.html`**（项目根目录）— 变更影响分析报告。分析完成后**必须将报告写入此文件**，不能仅在对话中输出文本。
- ⚠️ **强制要求：报告 HTML 必须严格按照 [ReportTemplate.html](./resources/ReportTemplate.html) 1:1 还原**，包括完整的 `<style>` 块、所有 CSS 变量、每个 HTML 元素的 class 名称、嵌套层级、`<script>` 块。**不得自创样式、不得省略任何 CSS 规则、不得改变 HTML 结构层级**。详见下方「报告 HTML 结构严格规范」章节。

## 组件标题回退机制

当路由的菜单标题字段缺失或不含中文时，需按**项目类型**使用不同的回退策略。

> 📖 详细回退规则请参考对应的框架技能（`react-change-impact` 或 `vue-change-impact`）。

### 通用原则

- 所有来源**均只提取含中文字符的结果**，避免英文组件名被误用为菜单名称。
- 不同框架的标题字段、回退 API 完全不同，**严禁混用**，具体见对应框架技能。

### 标题解析优先级

按以下顺序确定页面标题：

1. 路由菜单标题字段（含中文时使用，具体字段名见对应框架技能）
2. `src/app.json` 中对应 `path` 的 `title`（脚本自动探测）
3. 组件文件标题回退（回退规则详见对应框架技能）
4. 路径分段兜底（仅供人工审核，**生产报告中必须替换为中文**）

### 菜单路径格式规范

- ✅ 必须使用**用户在 App/网站中实际看到的菜单名称**
- ✅ 层级之间用 ` > ` 分隔，如 `一级菜单 > 二级菜单 > 三级菜单`
- ❌ **不能用英文文件夹名/路由 path 段直译**（如 `setting > scheduleSet`）
- ❌ **不能用代码变量名**（如 `ScheduleSet`、`OrderCheck`）
- 如果某个路由找不到中文标题 → 查看引用该路由的页面/菜单列表组件，确认真实入口名称

## 关键规范速查

- 路由映射只关心 `path` → 菜单路径，与文件目录无关。
- 若路由菜单标题字段缺失或无中文 → 按对应框架技能的标题回退机制依次查找，**绝不用路径段直译**。
- 影响分级：引用次数 < 2 的变更文件不纳入分析，基于受影响功能在 faultRating 表中的等级（P0/P1/P2/P3），详见对应框架技能的 `resources/faultRating.md`；功能不在表中时默认给 **P3**。
- 业务触发路径必须用**中文业务语言**描述（用户操作步骤，非代码路径）。

## 菜单路径判断方法

**正确方法**：在代码中搜索「谁在调用这个路由 path」，确认用户实际从哪个业务流程触达这个页面（具体搜索模式见对应框架技能中的「搜索菜单入口的方法」章节）。

当自动推断不准确时，可以进一步排查：
1. 如项目有统一菜单/设置列表页，读取其模板中的分区标题和菜单项标题来确定真实层级
2. 如项目有页面注册表（`app.json` 等），优先使用其中的 `title` 字段

**三类路由**：

| 类型 | 定义 | 菜单路径取法 |
|------|------|------------|
| 直达菜单路由 | 用户点导航栏/菜单直接进入 | 该菜单项本身 |
| 子流程路由 | 由另一页面跳入，非独立入口 | 触发入口所在菜单（需人工确认后在报告中标注） |
| 多入口路由 | 可从多个菜单触达 | 列出所有入口，如 `多入口（A / B / C）` |

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
2. 读取对应框架技能的 `resources/faultRating.md`，在功能等级列表中查找该功能
3. 取匹配行的等级列作为影响等级
4. **若功能不在 faultRating 表中，默认评定为 P3**

> 📖 faultRating 表位置：
> - React 项目：[react-change-impact/resources/faultRating.md](../react-change-impact/resources/faultRating.md)
> - Vue 项目：[vue-change-impact/resources/faultRating.md](../vue-change-impact/resources/faultRating.md)

## 最佳实践 (Best Practices)

- 对共享组件（`src/common/`、`src/components/`、`src/shared/`）重点关注引用面，共享组件变更可能同时影响多个功能，需逐一查表评级。
- 报告中的触发操作用用户操作步骤描述，非代码逻辑。

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

## 注意事项 (Precautions)

- ❌ 不要用**文件目录/路由模块名**直接推断菜单路径（同名目录不等于同名菜单）
- ❌ 不要忽略**子流程路由**：从其他页面跳入的路由，菜单路径是「触发入口」所在菜单
- ❌ 不要漏掉**多入口路由**：可从多个菜单触达的页面，要列出所有入口
- ❌ 不要把仅被同目录文件引用的变更标为高影响
- ❌ 路由无中文标题时，**不要直接用路径段作为菜单名**，先按对应框架技能的回退机制查找
- ❌ **不要输出英文路由段**（如 `enroll > orderCheck`），报告中所有菜单路径必须是中文

## 工具与资源

| 文件 | 用途 |
|------|------|
| [scripts/get-changed-files.sh](./scripts/get-changed-files.sh) | 获取变更文件（可配置排除目录） |
| [resources/ReportTemplate.html](./resources/ReportTemplate.html) | 报告输出模板（HTML） |
| [examples/INDEX.md](./examples/INDEX.md) | 示例文档导航 |

