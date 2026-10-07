const STORAGE_KEY = 'time_manager_pending_events'
const DB_NAME = 'time_manager'
const DB_VERSION = 1
let sqliteDatabasePromise

function hasSqlite() {
  return typeof window !== 'undefined' && Boolean(window.sqlitePlugin)
}

function readFallback() {
  try {
    return JSON.parse(window.localStorage.getItem(STORAGE_KEY) || '[]')
  } catch {
    return []
  }
}

function writeFallback(events) {
  window.localStorage.setItem(STORAGE_KEY, JSON.stringify(events))
}

function openSqlite() {
  if (!hasSqlite()) return Promise.resolve(null)
  if (!sqliteDatabasePromise) {
    sqliteDatabasePromise = new Promise((resolve, reject) => {
      try {
        const database = window.sqlitePlugin.openDatabase({ name: DB_NAME, location: 'default' })
        database.transaction((transaction) => {
          transaction.executeSql(
            `CREATE TABLE IF NOT EXISTS pending_events (
              local_id INTEGER PRIMARY KEY AUTOINCREMENT,
              client_event_id TEXT NOT NULL UNIQUE,
              user_id INTEGER NOT NULL,
              event_type TEXT NOT NULL,
              occurred_at TEXT NOT NULL,
              created_at TEXT NOT NULL,
              status TEXT NOT NULL,
              retry_count INTEGER NOT NULL DEFAULT 0,
              last_error TEXT
            )`,
            []
          )
        }, reject, () => resolve(database))
      } catch (error) {
        reject(error)
      }
    }).catch(() => null)
  }
  return sqliteDatabasePromise
}

function execute(database, sql, params = []) {
  return new Promise((resolve, reject) => {
    database.transaction((transaction) => {
      transaction.executeSql(sql, params, (_tx, result) => resolve(result), (_tx, error) => {
        reject(error)
        return false
      })
    }, reject)
  })
}

export async function listPendingEvents() {
  const database = await openSqlite()
  if (database) {
    const result = await execute(database, 'SELECT * FROM pending_events WHERE status != ? ORDER BY occurred_at ASC', ['synced'])
    return Array.from({ length: result.rows.length }, (_, index) => result.rows.item(index))
  }
  return readFallback().filter((event) => event.status !== 'synced').sort((a, b) => a.occurred_at.localeCompare(b.occurred_at))
}

export async function enqueueEvent(event) {
  const database = await openSqlite()
  if (database) {
    await execute(database, `INSERT INTO pending_events
      (client_event_id, user_id, event_type, occurred_at, created_at, status)
      VALUES (?, ?, ?, ?, ?, ?)`, [
      event.client_event_id,
      event.user_id,
      event.event_type,
      event.occurred_at,
      event.created_at,
      'pending'
    ])
    return event
  }
  const events = readFallback()
  events.push({ ...event, status: 'pending', retry_count: 0, last_error: null })
  writeFallback(events)
  return event
}

export async function updateEvent(event, changes) {
  const database = await openSqlite()
  if (database) {
    await execute(database, `UPDATE pending_events
      SET status = ?, retry_count = ?, last_error = ?
      WHERE client_event_id = ?`, [
      changes.status ?? event.status,
      changes.retry_count ?? event.retry_count ?? 0,
      changes.last_error ?? null,
      event.client_event_id
    ])
    return
  }
  const events = readFallback().map((item) => item.client_event_id === event.client_event_id
    ? { ...item, ...changes }
    : item)
  writeFallback(events)
}

export async function removeEvent(event) {
  const database = await openSqlite()
  if (database) {
    await execute(database, 'DELETE FROM pending_events WHERE client_event_id = ?', [event.client_event_id])
    return
  }
  writeFallback(readFallback().filter((item) => item.client_event_id !== event.client_event_id))
}

export async function clearLocalDatabase() {
  const database = await openSqlite()
  if (database) {
    await execute(database, 'DELETE FROM pending_events')
  }
  if (typeof window !== 'undefined') window.localStorage.removeItem(STORAGE_KEY)
}
