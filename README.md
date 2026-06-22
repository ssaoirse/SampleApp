# SampleApp

A SwiftUI product-browsing app built on top of the [DummyJSON](https://dummyjson.com) public API. Users can browse, search, filter, and sort a paginated product catalogue.

## Features

- **Product list** — paginated infinite scroll with automatic load-more
- **Search** — debounced full-text search (1 s delay, cancels in-flight requests)
- **Filter & sort** — filter by category, sort by title, price, rating, stock, or discount
- **Error handling** — per-state error messages with inline retry
- **Loading states** — distinct states for initial load, load-more, and errors so the UI never blocks

## Requirements

| | |
|---|---|
| iOS | 26.2+ |
| Xcode | 15.0+ |
| Swift | 6.0+ |

No third-party dependencies.

## Architecture

The project follows **MVVM** with protocol-driven dependency injection throughout, making every layer independently testable.

```
View  →  ViewModel (protocol)  →  Service (protocol)  →  APIClient  →  URLSession
```

### Networking

| File | Role |
|---|---|
| `Endpoint` | Protocol that describes a request: path, query items, response type, and JSON mapping |
| `APIClient` | Generic `fetch<E: Endpoint>()` that handles transport, status-code validation, and error mapping |
| `APIError` | Typed error enum (`invalidUrl`, `invalidResponse`, `requestFailed`, `networkError`, `taskCancelled`) |

### Products feature

| Layer | Type | Notes |
|---|---|---|
| `ProductsEndpoint` | `Endpoint` | Builds `/products`, `/products/search`, or `/products/category/{name}` based on a `Configuration` value |
| `ProductService` | Protocol | `DefaultProductService` wraps `APIClient`; `MockProductsService` is used in tests |
| `DefaultProductsViewModel` | `@Observable` | Owns `loadingState`, `products`, `configuration`; guards against duplicate loads; debounces search; cancels stale tasks |
| `ProductsListView` | Generic SwiftUI view | Parameterised over `ProductsViewModel` and `CategoryViewModel` protocols |

### Filters feature

| Layer | Type | Notes |
|---|---|---|
| `CategoryEndpoint` | `Endpoint` | `/products/category-list` → `[String]` |
| `CategoryService` | Protocol | `DefaultCategoryService` wraps `APIClient` |
| `DefaultCategoryViewModel` | `@Observable` | Fetches categories once and caches them for the session |
| `FilterProductsView` | Generic SwiftUI view | Sheet with Sort By and Category pickers |

### Loading states

```
.initial → .loading → .loadingComplete
                    ↘ .loadingError(message)   ← retry button
         → .loadingMore → .loadingComplete
                        ↘ .loadingMoreError(message)
```

## Known Limitations
 
**Search is disabled when a category filter is active.**
The DummyJSON API does not support filtering by both category and search term in a single request — the two are mutually exclusive endpoints (`/products/category/{name}` vs `/products/search?q=`). When a category is selected, the search bar is still visible but any search input is silently ignored; the list continues to show results for the active category only. To search across all products, clear the category filter first.

