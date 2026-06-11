# Motivation

## The Problem

**Every tool solves one thing, none solve everything.**

Notes live in Notion (can't publish or sell). Content lives in WordPress (plugin hell, browser-only admin, no offline). Products live in Shopify (walled garden, no content or CRM). Customers live in Salesforce (separate product, per-seat licensing, no offline). Your work is fragmented across tools that don't talk to each other.

**Existing platforms force trade-offs.**

- **WordPress** won the web but its plugin model means bloat, security surface, upgrade nightmares. Every feature requires vetting, maintaining, and praying a third-party developer keeps it alive.
- **Shopify** is a walled garden — you don't own your store, your data, or your customer relationships.
- **Salesforce** requires a separate purchase, custom code (Apex), and an always-on connection.
- **Notion / Obsidian** are great for notes but can't publish to the web, sell products, or manage customers.
- **SquareSpace / Wix** are centralized, browser-only, and lock you into their hosting.

**No platform combines content, commerce, and CRM in one modular, offline-first, opinionated system.**

## The Approach

**One platform. Every module built-in. No plugins.**

The server is a modular monolith — deploy only the modules your use case needs. Notes, tasks, products, CRM, forums, wiki — all built on the same data model, all synced with the same offline-first engine, all accessible from the same cross-platform client.

**Multi-server by architecture, not retrofit.**

The client connects to any number of independent servers, each fully self-contained. Browse public content from any server, switch between accounts on different servers, manage credentials per server. No server-to-server federation — the client is the bridge.

**No plugins.** Extensibility comes through webhooks and built-in modules, not third-party code running on your server.

**Offline-first.** Write notes, edit products, update deals — all without a connection. Sync when you reconnect.

**Social as infrastructure.** Follows, likes, comments, feed — not plugins, not afterthoughts. Built into the platform from day one.

**Commerce as a content type.** Products, cart, payments — same data model as notes, same offline discipline, same multi-server browsing.

**CRM as a content type.** Contacts, deals, pipeline — structured data with the same sync, search, and social features as everything else.

## Competitive Landscape

| Competitor | HiNeat's Difference |
|------------|---------------------|
| **WordPress** | No plugins — all modules built-in. Native cross-platform client with offline sync. Multi-server content browsing. |
| **Shopify** | Not a walled garden — self-host, your data, your customers. Content + commerce + CRM in one model. |
| **Salesforce** | CRM as a built-in module, not a separate product. Offline-native. No per-seat licensing. Self-hostable. |
| **Notion / Obsidian** | Can publish, sell, socialize — not just take notes. Multi-server browsing. Open source, self-hostable. |
| **Odoo** | Modular monolith analogue — validates the architecture. Gap: browser-only, no offline, no multi-server. |
| **SquareSpace / Wix** | Native client with offline authoring. No vendor lock-in — self-hostable, multi-server. |
| **Reddit** | Content discovery + topic structure on your own server. Threads and categories with social features. |
| **eBay** | Multi-server marketplace analogue — browse products across independent servers. Same model, not federated. |
| **Zoho** | Product breadth validates demand for unified tools. Gap: separate codebases, no offline, centralized. |

## Inspirations

| Inspiration | What it contributed |
|-------------|---------------------|
| **WordPress** | Content model — posts, pages, custom types |
| **eBay** | Multi-server marketplace — browse listings across servers |
| **Reddit** | Social content discovery — threads, comments, topic structure |
| **Salesforce** | Structured data + pipeline views — contacts, deals, activities |
| **SharePoint** | Structured content with granular permissions — 3-tier visibility inspiration |
| **OneDrive** | Offline-first sync with conflict resolution |
| **Obsidian** | Local-first, markdown-native writing experience |
| **Odoo** | Validates the modular monolith approach |
| **Ghost** | Opinionated, built-in commerce (memberships, subscriptions) |

## Design Principles

- **Built-in over bolted-on** — every module is native. No plugin ecosystem, no dependency hell.
- **Modular monolith** — ship the modules you need, nothing more. Toggle at deploy time.
- **Offline-first** — write without connectivity, sync when available.
- **Multi-server** — the client connects to any number of servers. Each server is standalone.
- **Privacy as a spectrum** — LOCAL (device only), PRIVATE (synced), PUBLIC (browsable).
- **One codebase, all platforms** — Compose Multiplatform, shared logic across Android, iOS, Desktop, Web.

### Opinionated Trade-Offs

| Not building | Why |
|-------------|-----|
| Plugin API / marketplace | Contradicts the thesis. Extensibility is through webhooks and built-in modules. |
| Drag-and-drop page builder | Fixed markdown templates. Opinionated design, not infinite configurability. |
| Form builder | Fixed form types (contact, feedback, survey). No drag-and-drop builder. |
| Kanban drag-and-drop | Lists with tap-to-move. Drag-and-drop is unreliable on Web/Wasm. |
| Custom CRM pipeline stages | One fixed pipeline. No configuration UI. |
| Theme marketplace | Fixed templates designed for the platform. |
| Infinite nesting | Forum categories capped at one level (category → subcategory). Wiki at space → category → page. |

**Spaces** (permission-scoped content containers for teams/organizations) are recognized as a future need but deferred past MVP. 3-tier visibility covers the initial use cases.

## Planned Modules

### Current

- Notes — CRUD with Markdown rendering
- Tasks — CRUD with task list toggle

### In Development

- Social — feed, follows, likes, comments, notifications

### Build

- Wiki / Knowledge — structured documentation with hierarchy and search
- Forum / Community — threads, categories, replies with multi-server browsing
- Digital Goods — products, subscriptions, cart, Stripe payments
- Forms / Surveys — data collection with offline submission
- Bookmarks / Collections — save and organize content from any server
- Calendar / Scheduling — events, dates, booking overlay with commerce
- Newsletters / Digests — scheduled email digests of followed content
- Media Library — shared file management across all content modules
- Invoicing / Billing — invoice generation from deals or purchases

### Deferred

- CMS (public web rendering) — blocked on web rendering approach
- Project Management — projects, sprints, boards (after tasks mature)
- CRM — contacts, deals, pipeline, activity history
- Full Communication — chat, DMs, real-time messaging
- Basic Chat — lightweight channel chat (less deferred, still deferred)
- E-Learning — courses, lessons, quizzes, progress tracking
- Physical E-Commerce — shipping, inventory, tax, returns

### Core Infrastructure

- **Search** — full-text across all content types and servers
- **Tags / Taxonomies** — cross-module, cross-server content classification
- **Version History** — per-item audit log with diff and restore
- **Import / Export** — content portability (no lock-in)
- **Webhooks** — outbound events for external integrations
