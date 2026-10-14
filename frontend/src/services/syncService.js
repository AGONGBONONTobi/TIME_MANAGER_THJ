import api from './api'
import { enqueueEvent, listPendingEvents, removeEvent, updateEvent } from './localDatabase'
import { isOnline } from './networkService'
import { notifySync } from './nativeFeatures'
import { readAuthUser } from '../utils/auth'

let isSyncing = false
let syncRequested = false

function publish() {
  if (typeof window !== 'undefined') window.dispatchEvent(new CustomEvent('time-manager-sync'))
}

export async function queueClockEvent({ userId, eventType, occurredAt }) {
  const event = {
    client_event_id: globalThis.crypto?.randomUUID?.() || `mobile-${Date.now()}-${Math.random().toString(16).slice(2)}`,
    user_id: Number(userId),
    event_type: eventType,
    occurred_at: occurredAt,
    created_at: new Date().toISOString()
  }
  await enqueueEvent(event)
  publish()
  if (isOnline()) {
    synchronisePendingEvents().catch((error) => {
      console.error('Impossible de synchroniser les pointages en attente.', error)
    })
  }
  return event
}

export async function synchronisePendingEvents() {
  if (!isOnline()) return
  if (isSyncing) {
    syncRequested = true
    return
  }
  const userId = readAuthUser()?.id
  if (!userId) return

  isSyncing = true
  const attemptedEventIds = new Set()
  try {
    let synchronisedCount = 0
    do {
      syncRequested = false
      const events = (await listPendingEvents()).filter((event) =>
        Number(event.user_id) === Number(userId) && !attemptedEventIds.has(event.client_event_id)
      )

      for (const event of events) {
        attemptedEventIds.add(event.client_event_id)
        await updateEvent(event, { status: 'syncing' })
        try {
          await api.clockInOut(event.user_id, {
            client_event_id: event.client_event_id,
            event_type: event.event_type,
            occurred_at: event.occurred_at
          })
          await removeEvent(event)
          synchronisedCount += 1
        } catch (error) {
          await updateEvent(event, {
            status: 'failed',
            retry_count: (event.retry_count || 0) + 1,
            last_error: error?.message || 'Synchronisation impossible'
          })
          if (!error?.response || error.response.status >= 500) break
        }
        if (synchronisedCount > 0) notifySync(`${synchronisedCount} pointage(s) synchronisé(s).`)
      }
    } while (syncRequested && isOnline())
  } finally {
    isSyncing = false
    syncRequested = false
    publish()
  }
}

export async function pendingEventCount() {
  const userId = readAuthUser()?.id
  if (!userId) return 0
  return (await listPendingEvents()).filter((event) => Number(event.user_id) === Number(userId)).length
}
