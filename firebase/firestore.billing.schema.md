# Nutonium Shared Billing Schema (Mobile + Web)

This schema is designed for Firestore query-first access with denormalized invoice summaries.

## Collections

## 1) users
`users/{uid}`
- role: "retailer" | "wholesaler" | "customer"
- displayName, phoneNumber, email
- businessRef: DocumentReference (`retailers/{uid}` or `wholesalers/{uid}`)
- isProfileComplete: bool
- createdAt, updatedAt

## 2) retailers
`retailers/{uid}`
- ownerName, shopName
- gstNumber, businessLicense
- location: { city, state, pincode, address, geoHash }
- createdAt, updatedAt

## 3) wholesalers
`wholesalers/{uid}`
- ownerName, companyName
- gstNumber, panNumber, businessLicense
- location: { city, state, pincode, address, geoHash }
- createdAt, updatedAt

## 4) billing_accounts
`billing_accounts/{accountId}`
- ownerUid
- accountType: "retailer" | "wholesaler"
- businessName
- gstNumber
- currency: "INR"
- invoicePrefix (ex: NUT-RT)
- nextInvoiceNumber (int)
- isActive
- createdAt, updatedAt

## 5) customers
`customers/{customerId}`
- accountId
- name
- phone
- email
- gstin
- billingAddress
- shippingAddress
- city
- state
- pincode
- createdAt, updatedAt

Recommended query index field: `accountId + updatedAt desc`

## 6) products
`products/{productId}`
- accountId
- sku
- name
- unit
- hsnCode
- taxRate
- price
- stockQty
- isActive
- createdAt, updatedAt

Recommended query index field: `accountId + isActive + updatedAt desc`

## 7) invoices (header only, feed-optimized)
`invoices/{invoiceId}`
- accountId
- invoiceNumber
- invoiceDate
- customerId
- customerName (denormalized)
- customerPhone (denormalized)
- subtotal
- taxTotal
- discountTotal
- grandTotal
- amountPaid
- balanceDue
- status: "draft" | "issued" | "partial" | "paid" | "cancelled"
- paymentStatus: "unpaid" | "partial" | "paid"
- dueDate
- lineCount
- createdBy
- createdAt, updatedAt

⚠ Keep this document < 10KB.

Recommended query index fields:
- `accountId + invoiceDate desc`
- `accountId + status + invoiceDate desc`
- `accountId + customerId + invoiceDate desc`

## 8) invoice_items (separate to keep invoice doc small)
`invoices/{invoiceId}/items/{itemId}`
- productId
- name (denormalized)
- hsnCode
- qty
- unit
- unitPrice
- taxRate
- taxAmount
- lineTotal
- createdAt

## 9) payments
`payments/{paymentId}`
- accountId
- invoiceId
- invoiceNumber (denormalized)
- customerId
- amount
- mode: "cash" | "upi" | "bank" | "card"
- referenceNo
- paidAt
- createdBy
- createdAt

Recommended query index fields:
- `accountId + paidAt desc`
- `accountId + invoiceId + paidAt desc`

## 10) invoice_counters (sharded)
`invoice_counters/{accountId}/shards/{0..19}`
- issuedCountDelta
- paidCountDelta
- revenueDelta
- updatedAt

Use scheduled aggregation job to update dashboard docs.

## 11) billing_dashboard_daily
`billing_dashboard_daily/{accountId_yyyyMMdd}`
- accountId
- day
- invoiceCount
- paidCount
- dueCount
- grossRevenue
- taxCollected
- updatedAt

---

## Access Pattern Rules
- Web/mobile list screens read from `invoices` only (header summary), never invoice item subcollection unless details page opened.
- Duplicate customerName/customerPhone in invoice header to avoid joins.
- All list queries must use `where + orderBy + limit(20)`.
- No full collection scans.

## Suggested Limits
- `invoices` list page: `limit(20)`
- `customers` page: `limit(20)`
- `products` page: `limit(20)`
- invoice items per invoice: target <= 100
