# 标准分析流程

完整的变更影响分析流程，从 git diff 到输出报告。

## 前置条件

- 当前分支已有提交（相对于 master 存在 diff）
- 项目已安装依赖（`node_modules` 存在）
- 已安装 `typescript`（用于 AST 解析）

## 步骤一：获取变更文件

```bash
bash .github/skills/change-impact-analysis/scripts/get-changed-files.sh master
```

输出示例（路径因项目而异）：
```
src/components/shared-button/index.tsx
src/pages/order/list/index.tsx
src/pages/order/list/helpers.ts
src/hooks/useOrderForm.ts
```

## 步骤二：梳理路由映射关系

读取项目路由配置文件（`router.ts` / `routes.ts` 等），提取所有 `path` 与对应菜单标题字段（Vue 项目为 `meta.title`，React 项目为 `crumbs`）。

对无中文标题的路由，依次尝试：
1. 读取 `src/app.json` 中对应 `path` 的 `title`
2. 读取 `component` 组件文件，提取导航条、`defineOptions` 等属的中文标题
3. 最终无法自动推断的，在报告中保留占位符等待人工确认

> **组件标题回退**：脚本会自动尝试从路由的 `component` 组件文件中提取中文标题（当菜单标题字段缺失或非中文时，React 项目为 `crumbs`，Vue 项目为 `meta.title`，详见对应指南），无需手动补充。

## 步骤三：分析引用关系

对每个变更文件，在 `src/` 目录中搜索其被 import 的位置：

### AI 执行方式

1. 读取变更文件，提取导出符号
2. 用 `grep_search` 在 `src/` 下搜索 `from '...<变更文件路径>'` 或 `from "<变更文件路径>"`
3. 收集所有引用文件路径

### 引用数过滤

```
引用数 ≥ 2  → 纳入分析
引用数 < 2  → ⚪ 内部文件（跳过）
```

### 影响等级评定

根据变更文件关联的受影响菜单/功能，在对应 faultRating 表中查找等级（P0/P1/P2/P3），功能不在表中默认 P3：
- React 项目：[resources/faultRating-react.md](../resources/faultRating-react.md)
- Vue 项目：[resources/faultRating-vue.md](../resources/faultRating-vue.md)

## 步骤四：关联菜单路径

将引用文件路径匹配到路由映射表：

1. 从引用文件路径向上查找最近的路由文件（`router.ts` / `routes.ts` 等）
2. 在路由映射中查找对应的菜单路径
3. 若路由无中文菜单路径，需搜索触发入口确认用户实际从哪个自然语言操作进入

### 路径匹配示例

```
引用文件: src/pages/order/list/index.tsx
↓ 向上查找路由文件
router: src/pages/order/router.ts
↓ 在路由配置中查找 meta.title 或搜索触发入口
菜单路径: 订单管理（或该路由菜单标题字段的値）
```

## 步骤五：生成报告并写入文件

**先完整读取** [ReportTemplate.html](../resources/ReportTemplate.html)，然后严格按模板的 HTML 结构、CSS 样式、JS 脚本进行 1:1 还原，仅替换占位符和填充动态数据，**将报告写入项目根目录的 `CHANGE_IMPACT_REPORT.html`**。

### 关键要求

- **先读模板** — 生成前必须用 `read_file` 完整读取 `ReportTemplate.html`，确保 CSS/JS 原样复制
- **区块一（变更文件总览）** — `.section#section1`，按模块分组（`.module-group`），包含所有变更文件的表格
- **区块二（功能维度）** — `.section#section2`，每个变更文件一个 `.detail-card`，含变更摘要、引用位置、影响页面表格
- **区块三（业务维度）** — `.section#section3`，按回归范围分组（`.regression-group`），含优先级、菜单路径、触发操作
- **输出文件** — `CHANGE_IMPACT_REPORT.html` 写入项目根目录，已存在时覆盖
- ⚠️ **不得自创样式、不得省略CSS/JS、不得改变HTML层级结构**，详见 SKILL.md「报告 HTML 结构严格规范」

## 完整示例

> 假设当前分支修改了 `src/components/shared-button/index.tsx`

**步骤 1** — 获取变更文件列表 → 1 个文件

**步骤 2** — 梳理路由映射关系（读取路由配置文件）

**步骤 3** — 搜索引用：
```bash
grep -r "shared-button" src/ --include="*.ts" --include="*.tsx" --include="*.vue" -l
```
→ 找到 5 处引用

**步骤 4** — 匹配菜单路径（从路由配置中查找引用页面所属路由）：
- `src/pages/order/create/` → 订单管理 > 创建订单
- `src/pages/user/profile/` → 个人中心
- `src/pages/admin/settings/` → 管理后台 > 系统设置

**步骤 5** — 生成报告并写入 `CHANGE_IMPACT_REPORT.html`（见 ReportTemplate.html）

