# Admin 框架搭建 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 搭建 LittleGrid Admin 的完整前端框架：Material 风格顶栏+侧栏+内容区布局，所有菜单路由和占位页面。

**Architecture:** Next.js 16 App Router 布局嵌套。`/app/dashboard/layout.tsx` 作为 dashboard 根布局，包含 TopBar 和 Sidebar 组件。各菜单页面作为子路由，使用统一的占位页面组件。侧栏菜单配置集中定义，通过 `usePathname()` 高亮当前项。

**Tech Stack:** Next.js 16, React 19, Tailwind CSS 4, Material Icons (Google Fonts), shadcn/ui (暂不安装，本阶段纯 Tailwind 足够)

---

## File Structure

```
admin/
├── app/
│   ├── layout.tsx                          # Modify: 换字体为 Noto Sans SC
│   ├── globals.css                         # Modify: 添加 CSS 变量和 Material 主题
│   ├── page.tsx                            # Keep: 登录页不变
│   └── dashboard/
│       ├── layout.tsx                      # Modify: 重写为 TopBar + Sidebar + Content
│       ├── page.tsx                        # Modify: 首页占位
│       ├── users/
│       │   ├── app/page.tsx                # Create: APP 用户占位
│       │   └── admin/page.tsx              # Create: 管理员占位
│       ├── content/
│       │   ├── treehole/page.tsx           # Create: 树洞审核占位
│       │   └── reports/page.tsx            # Create: 举报处理占位
│       ├── payments/
│       │   ├── transactions/page.tsx       # Create: 交易记录占位
│       │   └── alipay/page.tsx            # Create: 支付宝配置占位
│       ├── ops/
│       │   ├── monitor/page.tsx            # Create: 监控占位
│       │   └── logs/page.tsx              # Create: 日志占位
│       ├── tools/
│       │   ├── upload/page.tsx             # Create: 文件上传占位
│       │   ├── database/page.tsx           # Create: 数据库管理占位
│       │   ├── storage/page.tsx            # Create: 存储管理占位
│       │   └── cache/page.tsx             # Create: 缓存管理占位
│       ├── settings/page.tsx               # Create: 系统设置占位
│       └── api-docs/page.tsx              # Create: API 文档占位
├── components/
│   ├── topbar.tsx                          # Create: 顶栏组件
│   ├── sidebar.tsx                         # Create: 侧栏组件
│   └── placeholder-page.tsx               # Create: 占位页面组件
└── lib/
    └── menu-config.ts                      # Create: 菜单配置数据
```

---

### Task 1: 全局样式和字体

**Files:**
- Modify: `admin/app/globals.css`
- Modify: `admin/app/layout.tsx`

- [ ] **Step 1: 更新 globals.css，定义 Material 主题 CSS 变量**

替换 `admin/app/globals.css` 全部内容为：

```css
@import "tailwindcss";

:root {
  --primary: #1a73e8;
  --primary-light: #e8f0fe;
  --primary-dark: #1557b0;
  --on-primary: #ffffff;
  --surface: #ffffff;
  --surface-dim: #f8f9fa;
  --surface-container: #f1f3f4;
  --surface-container-low: #f8f9fa;
  --on-surface: #1f1f1f;
  --on-surface-variant: #5f6368;
  --outline: #dadce0;
  --outline-variant: #e8eaed;
  --error: #d93025;
  --success: #1e8e3e;
  --warning: #f9ab00;
  --info: #1a73e8;
  --topbar-height: 64px;
  --sidebar-width: 256px;
}

@theme inline {
  --color-background: var(--surface-dim);
  --color-foreground: var(--on-surface);
  --font-sans: "Noto Sans SC", "Roboto", sans-serif;
  --font-mono: "Roboto Mono", monospace;
}

body {
  background: var(--surface-dim);
  color: var(--on-surface);
  font-family: var(--font-sans);
  -webkit-font-smoothing: antialiased;
}
```

- [ ] **Step 2: 更新 layout.tsx，加载 Noto Sans SC 和 Material Icons 字体**

替换 `admin/app/layout.tsx` 全部内容为：

```tsx
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "LittleGrid Admin",
  description: "LittleGrid 管理后台",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="zh-CN" className="h-full antialiased">
      <head>
        <link
          href="https://fonts.googleapis.com/css2?family=Noto+Sans+SC:wght@300;400;500;600;700&family=Roboto+Mono:wght@400;500&display=swap"
          rel="stylesheet"
        />
        <link
          href="https://fonts.googleapis.com/icon?family=Material+Icons+Round"
          rel="stylesheet"
        />
      </head>
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}
```

- [ ] **Step 3: 验证开发服务器启动**

Run: `cd /Users/nano/claude/little-grid/admin && npm run dev`
Expected: 编译成功，无报错

- [ ] **Step 4: Commit**

```bash
git add admin/app/globals.css admin/app/layout.tsx
git commit -m "feat(admin): set up Material theme and Noto Sans SC font"
```

---

### Task 2: 菜单配置数据

**Files:**
- Create: `admin/lib/menu-config.ts`

- [ ] **Step 1: 创建菜单配置文件**

```bash
mkdir -p /Users/nano/claude/little-grid/admin/lib
```

创建 `admin/lib/menu-config.ts`：

```ts
export interface MenuItem {
  label: string
  icon: string
  href?: string
  children?: { label: string; href: string }[]
}

export const menuItems: MenuItem[] = [
  { label: '首页', icon: 'dashboard', href: '/dashboard' },
  {
    label: '用户管理',
    icon: 'people',
    children: [
      { label: 'APP 用户', href: '/dashboard/users/app' },
      { label: '管理员', href: '/dashboard/users/admin' },
    ],
  },
  {
    label: '内容管理',
    icon: 'article',
    children: [
      { label: '树洞审核', href: '/dashboard/content/treehole' },
      { label: '举报处理', href: '/dashboard/content/reports' },
    ],
  },
  {
    label: '支付管理',
    icon: 'payment',
    children: [
      { label: '交易记录', href: '/dashboard/payments/transactions' },
      { label: '支付宝配置', href: '/dashboard/payments/alipay' },
    ],
  },
  {
    label: '运维',
    icon: 'monitor_heart',
    children: [
      { label: '监控', href: '/dashboard/ops/monitor' },
      { label: '日志', href: '/dashboard/ops/logs' },
    ],
  },
  {
    label: '工具',
    icon: 'build',
    children: [
      { label: '文件上传', href: '/dashboard/tools/upload' },
      { label: '数据库管理', href: '/dashboard/tools/database' },
      { label: '存储管理', href: '/dashboard/tools/storage' },
      { label: '缓存管理', href: '/dashboard/tools/cache' },
    ],
  },
  { label: '系统设置', icon: 'tune', href: '/dashboard/settings' },
  { label: 'API 文档', icon: 'api', href: '/dashboard/api-docs' },
]
```

- [ ] **Step 2: Commit**

```bash
git add admin/lib/menu-config.ts
git commit -m "feat(admin): add centralized menu configuration"
```

---

### Task 3: 顶栏组件

**Files:**
- Create: `admin/components/topbar.tsx`

- [ ] **Step 1: 创建 TopBar 组件**

```bash
mkdir -p /Users/nano/claude/little-grid/admin/components
```

创建 `admin/components/topbar.tsx`：

```tsx
'use client'

export function TopBar() {
  return (
    <header
      className="fixed top-0 left-0 right-0 z-50 flex items-center justify-between px-4 bg-white border-b"
      style={{ height: 'var(--topbar-height)', borderColor: 'var(--outline)' }}
    >
      <div className="flex items-center gap-3">
        <div className="flex items-center gap-2.5">
          <div
            className="flex items-center justify-center rounded-lg font-bold text-sm text-white"
            style={{ width: 36, height: 36, background: 'var(--primary)' }}
          >
            LG
          </div>
          <span className="text-lg font-semibold" style={{ color: 'var(--on-surface)' }}>
            LittleGrid
          </span>
        </div>
        <div className="relative ml-6">
          <span
            className="material-icons-round absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none"
            style={{ fontSize: 20, color: 'var(--on-surface-variant)' }}
          >
            search
          </span>
          <input
            type="text"
            placeholder="搜索..."
            className="h-10 w-[340px] rounded-full border bg-[var(--surface-container-low)] pl-11 pr-4 text-sm outline-none transition-all focus:border-[var(--primary)] focus:bg-white focus:ring-2 focus:ring-[var(--primary-light)]"
            style={{ borderColor: 'var(--outline)', color: 'var(--on-surface)' }}
          />
        </div>
      </div>
      <div className="flex items-center gap-1">
        <button
          className="flex items-center justify-center rounded-full transition-colors hover:bg-[var(--surface-container)] relative"
          style={{ width: 40, height: 40, color: 'var(--on-surface-variant)' }}
        >
          <span className="material-icons-round" style={{ fontSize: 22 }}>notifications_none</span>
          <span
            className="absolute rounded-full border-2 border-white"
            style={{ width: 8, height: 8, background: 'var(--error)', top: 9, right: 9 }}
          />
        </button>
        <button
          className="flex items-center justify-center rounded-full transition-colors hover:bg-[var(--surface-container)]"
          style={{ width: 40, height: 40, color: 'var(--on-surface-variant)' }}
        >
          <span className="material-icons-round" style={{ fontSize: 22 }}>settings</span>
        </button>
        <div
          className="flex items-center justify-center rounded-full text-sm font-semibold text-white ml-2 cursor-pointer"
          style={{ width: 36, height: 36, background: 'var(--primary)' }}
        >
          A
        </div>
      </div>
    </header>
  )
}
```

- [ ] **Step 2: Commit**

```bash
git add admin/components/topbar.tsx
git commit -m "feat(admin): add TopBar component"
```

---

### Task 4: 侧栏组件

**Files:**
- Create: `admin/components/sidebar.tsx`

- [ ] **Step 1: 创建 Sidebar 组件**

创建 `admin/components/sidebar.tsx`：

```tsx
'use client'

import { useState } from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { menuItems } from '@/lib/menu-config'

export function Sidebar() {
  const pathname = usePathname()
  const [expanded, setExpanded] = useState<Record<string, boolean>>({})

  const toggleExpand = (label: string) => {
    setExpanded((prev) => ({ ...prev, [label]: !prev[label] }))
  }

  const isItemActive = (href: string) => pathname === href
  const isParentActive = (children: { href: string }[]) =>
    children.some((c) => pathname === c.href)

  return (
    <aside
      className="fixed left-0 bottom-0 overflow-y-auto py-2 bg-white border-r"
      style={{
        top: 'var(--topbar-height)',
        width: 'var(--sidebar-width)',
        borderColor: 'var(--outline)',
      }}
    >
      <nav className="flex flex-col gap-0.5 px-3">
        {menuItems.map((item) => {
          if (item.children) {
            const parentActive = isParentActive(item.children)
            const isOpen = expanded[item.label] || parentActive

            return (
              <div key={item.label}>
                <button
                  onClick={() => toggleExpand(item.label)}
                  className="flex items-center gap-3.5 w-full h-11 px-4 rounded-lg text-sm transition-colors cursor-pointer"
                  style={{
                    color: parentActive ? 'var(--primary)' : 'var(--on-surface-variant)',
                    background: parentActive ? 'var(--primary-light)' : 'transparent',
                    fontWeight: parentActive ? 500 : 400,
                  }}
                  onMouseEnter={(e) => {
                    if (!parentActive) e.currentTarget.style.background = 'var(--surface-container)'
                  }}
                  onMouseLeave={(e) => {
                    if (!parentActive) e.currentTarget.style.background = 'transparent'
                  }}
                >
                  <span className="material-icons-round" style={{ fontSize: 20 }}>{item.icon}</span>
                  <span>{item.label}</span>
                  <span
                    className="material-icons-round ml-auto transition-transform"
                    style={{
                      fontSize: 18,
                      color: 'var(--on-surface-variant)',
                      transform: isOpen ? 'rotate(90deg)' : 'rotate(0)',
                    }}
                  >
                    chevron_right
                  </span>
                </button>
                <div
                  className="overflow-hidden transition-[max-height] duration-200"
                  style={{ maxHeight: isOpen ? 300 : 0 }}
                >
                  {item.children.map((child) => (
                    <Link
                      key={child.href}
                      href={child.href}
                      className="flex items-center gap-3.5 h-[38px] pl-[50px] pr-4 rounded-lg text-[13px] transition-colors"
                      style={{
                        color: isItemActive(child.href) ? 'var(--primary)' : 'var(--on-surface-variant)',
                        background: isItemActive(child.href) ? 'var(--primary-light)' : 'transparent',
                        fontWeight: isItemActive(child.href) ? 500 : 400,
                      }}
                      onMouseEnter={(e) => {
                        if (!isItemActive(child.href)) e.currentTarget.style.background = 'var(--surface-container)'
                      }}
                      onMouseLeave={(e) => {
                        if (!isItemActive(child.href)) e.currentTarget.style.background = 'transparent'
                      }}
                    >
                      <span
                        className="shrink-0 rounded-full transition-all"
                        style={{
                          width: 6,
                          height: 6,
                          background: isItemActive(child.href) ? 'var(--primary)' : 'var(--outline)',
                        }}
                      />
                      {child.label}
                    </Link>
                  ))}
                </div>
              </div>
            )
          }

          return (
            <Link
              key={item.label}
              href={item.href!}
              className="flex items-center gap-3.5 h-11 px-4 rounded-lg text-sm transition-colors"
              style={{
                color: isItemActive(item.href!) ? 'var(--primary)' : 'var(--on-surface-variant)',
                background: isItemActive(item.href!) ? 'var(--primary-light)' : 'transparent',
                fontWeight: isItemActive(item.href!) ? 500 : 400,
              }}
              onMouseEnter={(e) => {
                if (!isItemActive(item.href!)) e.currentTarget.style.background = 'var(--surface-container)'
              }}
              onMouseLeave={(e) => {
                if (!isItemActive(item.href!)) e.currentTarget.style.background = 'transparent'
              }}
            >
              <span className="material-icons-round" style={{ fontSize: 20 }}>{item.icon}</span>
              <span>{item.label}</span>
            </Link>
          )
        })}
      </nav>
      <div className="mt-4 mx-4 pt-4 border-t flex items-center gap-1.5 text-xs" style={{ borderColor: 'var(--outline-variant)', color: 'var(--on-surface-variant)' }}>
        <span className="material-icons-round" style={{ fontSize: 14 }}>info</span>
        v0.1.0 · build 2026.04
      </div>
    </aside>
  )
}
```

- [ ] **Step 2: Commit**

```bash
git add admin/components/sidebar.tsx
git commit -m "feat(admin): add Sidebar component with menu config"
```

---

### Task 5: 占位页面组件

**Files:**
- Create: `admin/components/placeholder-page.tsx`

- [ ] **Step 1: 创建占位页面组件**

创建 `admin/components/placeholder-page.tsx`：

```tsx
interface PlaceholderPageProps {
  title: string
  description?: string
}

export function PlaceholderPage({ title, description }: PlaceholderPageProps) {
  return (
    <div>
      <div className="mb-6">
        <h1 className="text-[22px] font-semibold" style={{ color: 'var(--on-surface)' }}>{title}</h1>
        {description && (
          <p className="text-sm mt-0.5" style={{ color: 'var(--on-surface-variant)' }}>{description}</p>
        )}
      </div>
      <div
        className="flex flex-col items-center justify-center rounded-xl border border-dashed py-20"
        style={{ borderColor: 'var(--outline)', background: 'var(--surface)' }}
      >
        <span className="material-icons-round mb-3" style={{ fontSize: 40, color: 'var(--outline)' }}>
          construction
        </span>
        <p className="text-sm" style={{ color: 'var(--on-surface-variant)' }}>功能开发中</p>
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```bash
git add admin/components/placeholder-page.tsx
git commit -m "feat(admin): add PlaceholderPage component"
```

---

### Task 6: Dashboard 布局

**Files:**
- Modify: `admin/app/dashboard/layout.tsx`

- [ ] **Step 1: 重写 dashboard layout 为 TopBar + Sidebar + Content**

替换 `admin/app/dashboard/layout.tsx` 全部内容为：

```tsx
'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { TopBar } from '@/components/topbar'
import { Sidebar } from '@/components/sidebar'

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const router = useRouter()

  useEffect(() => {
    const token = localStorage.getItem('adminToken')
    if (!token) {
      router.push('/')
    }
  }, [router])

  return (
    <div className="min-h-screen" style={{ background: 'var(--surface-dim)' }}>
      <TopBar />
      <Sidebar />
      <main
        className="overflow-y-auto"
        style={{
          position: 'fixed',
          top: 'var(--topbar-height)',
          left: 'var(--sidebar-width)',
          right: 0,
          bottom: 0,
          padding: '24px 32px 32px',
        }}
      >
        {children}
      </main>
    </div>
  )
}
```

- [ ] **Step 2: 验证布局正常显示**

Run: `cd /Users/nano/claude/little-grid/admin && npm run dev`
Expected: 访问 /dashboard 可看到顶栏、侧栏、内容区三段式布局

- [ ] **Step 3: Commit**

```bash
git add admin/app/dashboard/layout.tsx
git commit -m "feat(admin): rebuild dashboard layout with TopBar and Sidebar"
```

---

### Task 7: 首页

**Files:**
- Modify: `admin/app/dashboard/page.tsx`

- [ ] **Step 1: 更新首页为简单的欢迎页**

替换 `admin/app/dashboard/page.tsx` 全部内容为：

```tsx
import { PlaceholderPage } from '@/components/placeholder-page'

export default function DashboardPage() {
  return <PlaceholderPage title="首页" description="系统运行状态一览" />
}
```

- [ ] **Step 2: Commit**

```bash
git add admin/app/dashboard/page.tsx
git commit -m "feat(admin): update dashboard home page"
```

---

### Task 8: 创建所有子路由占位页面

**Files:**
- Create: `admin/app/dashboard/users/app/page.tsx`
- Create: `admin/app/dashboard/users/admin/page.tsx`
- Create: `admin/app/dashboard/content/treehole/page.tsx`
- Create: `admin/app/dashboard/content/reports/page.tsx`
- Create: `admin/app/dashboard/payments/transactions/page.tsx`
- Create: `admin/app/dashboard/payments/alipay/page.tsx`
- Create: `admin/app/dashboard/ops/monitor/page.tsx`
- Create: `admin/app/dashboard/ops/logs/page.tsx`
- Create: `admin/app/dashboard/tools/upload/page.tsx`
- Create: `admin/app/dashboard/tools/database/page.tsx`
- Create: `admin/app/dashboard/tools/storage/page.tsx`
- Create: `admin/app/dashboard/tools/cache/page.tsx`
- Create: `admin/app/dashboard/settings/page.tsx`
- Create: `admin/app/dashboard/api-docs/page.tsx`

- [ ] **Step 1: 创建目录结构**

```bash
mkdir -p /Users/nano/claude/little-grid/admin/app/dashboard/users/app
mkdir -p /Users/nano/claude/little-grid/admin/app/dashboard/users/admin
mkdir -p /Users/nano/claude/little-grid/admin/app/dashboard/content/treehole
mkdir -p /Users/nano/claude/little-grid/admin/app/dashboard/content/reports
mkdir -p /Users/nano/claude/little-grid/admin/app/dashboard/payments/transactions
mkdir -p /Users/nano/claude/little-grid/admin/app/dashboard/payments/alipay
mkdir -p /Users/nano/claude/little-grid/admin/app/dashboard/ops/monitor
mkdir -p /Users/nano/claude/little-grid/admin/app/dashboard/ops/logs
mkdir -p /Users/nano/claude/little-grid/admin/app/dashboard/tools/upload
mkdir -p /Users/nano/claude/little-grid/admin/app/dashboard/tools/database
mkdir -p /Users/nano/claude/little-grid/admin/app/dashboard/tools/storage
mkdir -p /Users/nano/claude/little-grid/admin/app/dashboard/tools/cache
mkdir -p /Users/nano/claude/little-grid/admin/app/dashboard/settings
mkdir -p /Users/nano/claude/little-grid/admin/app/dashboard/api-docs
```

- [ ] **Step 2: 创建所有占位页面文件**

`admin/app/dashboard/users/app/page.tsx`:
```tsx
import { PlaceholderPage } from '@/components/placeholder-page'

export default function AppUsersPage() {
  return <PlaceholderPage title="APP 用户" description="管理移动端注册用户" />
}
```

`admin/app/dashboard/users/admin/page.tsx`:
```tsx
import { PlaceholderPage } from '@/components/placeholder-page'

export default function AdminUsersPage() {
  return <PlaceholderPage title="管理员" description="管理后台管理员账号" />
}
```

`admin/app/dashboard/content/treehole/page.tsx`:
```tsx
import { PlaceholderPage } from '@/components/placeholder-page'

export default function TreeholePage() {
  return <PlaceholderPage title="树洞审核" description="审核和管理树洞帖子内容" />
}
```

`admin/app/dashboard/content/reports/page.tsx`:
```tsx
import { PlaceholderPage } from '@/components/placeholder-page'

export default function ReportsPage() {
  return <PlaceholderPage title="举报处理" description="处理用户举报内容" />
}
```

`admin/app/dashboard/payments/transactions/page.tsx`:
```tsx
import { PlaceholderPage } from '@/components/placeholder-page'

export default function TransactionsPage() {
  return <PlaceholderPage title="交易记录" description="查看支付交易流水" />
}
```

`admin/app/dashboard/payments/alipay/page.tsx`:
```tsx
import { PlaceholderPage } from '@/components/placeholder-page'

export default function AlipayConfigPage() {
  return <PlaceholderPage title="支付宝配置" description="管理支付宝支付参数" />
}
```

`admin/app/dashboard/ops/monitor/page.tsx`:
```tsx
import { PlaceholderPage } from '@/components/placeholder-page'

export default function MonitorPage() {
  return <PlaceholderPage title="监控" description="系统运行状态监控" />
}
```

`admin/app/dashboard/ops/logs/page.tsx`:
```tsx
import { PlaceholderPage } from '@/components/placeholder-page'

export default function LogsPage() {
  return <PlaceholderPage title="日志" description="查看系统运行日志" />
}
```

`admin/app/dashboard/tools/upload/page.tsx`:
```tsx
import { PlaceholderPage } from '@/components/placeholder-page'

export default function UploadPage() {
  return <PlaceholderPage title="文件上传" description="上传和管理文件资源" />
}
```

`admin/app/dashboard/tools/database/page.tsx`:
```tsx
import { PlaceholderPage } from '@/components/placeholder-page'

export default function DatabasePage() {
  return <PlaceholderPage title="数据库管理" description="查询和管理数据库" />
}
```

`admin/app/dashboard/tools/storage/page.tsx`:
```tsx
import { PlaceholderPage } from '@/components/placeholder-page'

export default function StoragePage() {
  return <PlaceholderPage title="存储管理" description="管理本地和 S3 存储" />
}
```

`admin/app/dashboard/tools/cache/page.tsx`:
```tsx
import { PlaceholderPage } from '@/components/placeholder-page'

export default function CachePage() {
  return <PlaceholderPage title="缓存管理" description="查看和管理 Redis 缓存" />
}
```

`admin/app/dashboard/settings/page.tsx`:
```tsx
import { PlaceholderPage } from '@/components/placeholder-page'

export default function SettingsPage() {
  return <PlaceholderPage title="系统设置" description="配置系统参数" />
}
```

`admin/app/dashboard/api-docs/page.tsx`:
```tsx
import { PlaceholderPage } from '@/components/placeholder-page'

export default function ApiDocsPage() {
  return <PlaceholderPage title="API 文档" description="查看后端 API 接口文档" />
}
```

- [ ] **Step 3: Commit**

```bash
git add admin/app/dashboard/users/ admin/app/dashboard/content/ admin/app/dashboard/payments/ admin/app/dashboard/ops/ admin/app/dashboard/tools/ admin/app/dashboard/settings/ admin/app/dashboard/api-docs/
git commit -m "feat(admin): add all menu route placeholder pages"
```

---

### Task 9: 端到端验证

- [ ] **Step 1: 启动开发服务器**

Run: `cd /Users/nano/claude/little-grid/admin && npm run dev`

- [ ] **Step 2: 验证所有路由可访问**

逐个访问以下路由，确认每个页面显示正确的标题和"功能开发中"占位：

- `/dashboard` - 首页
- `/dashboard/users/app` - APP 用户
- `/dashboard/users/admin` - 管理员
- `/dashboard/content/treehole` - 树洞审核
- `/dashboard/content/reports` - 举报处理
- `/dashboard/payments/transactions` - 交易记录
- `/dashboard/payments/alipay` - 支付宝配置
- `/dashboard/ops/monitor` - 监控
- `/dashboard/ops/logs` - 日志
- `/dashboard/tools/upload` - 文件上传
- `/dashboard/tools/database` - 数据库管理
- `/dashboard/tools/storage` - 存储管理
- `/dashboard/tools/cache` - 缓存管理
- `/dashboard/settings` - 系统设置
- `/dashboard/api-docs` - API 文档

- [ ] **Step 3: 验证侧栏交互**

- 当前页在侧栏对应项高亮
- 点击有子菜单的项可展开/收起
- 当前页所在父菜单自动展开
- 点击子菜单项跳转到对应页面

- [ ] **Step 4: 验证顶栏**

- Logo 和搜索框正常显示
- 通知/设置按钮 hover 效果正常

- [ ] **Step 5: 最终 commit（如有修复）**

```bash
git add -A
git commit -m "fix(admin): framework polish from end-to-end verification"
```
