import api from './api'
import { enqueueEvent, listPendingEvents, removeEvent, updateEvent } from './localDatabase'
import { isOnline } from './networkService'
import { notifySync } from './nativeFeatures'

let isSyncing = false

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
  if (isOnline()) await synchronisePendingEvents()
  return event
}

export async function synchronisePendingEvents() {
  if (!isOnline() || isSyncing) return
  isSyncing = true
  try {
    const events = await listPendingEvents()
    let synchronisedCount = 0
    const batchSize = 10
    for (let offset = 0; offset < events.length; offset += batchSize) {
      const batch = events.slice(offset, offset + batchSize)
      for (const event of batch) {
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
    }
  } finally {
    isSyncing = false
    publish()
  }
}

export async function pendingEventCount() {
  return (await listPendingEvents()).length
}
