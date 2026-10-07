import api from './api'
import { enqueueEvent, listPendingEvents, removeEvent, updateEvent } from './localDatabase'
import { isOnline } from './networkService'

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
    for (const event of events) {
      await updateEvent(event, { status: 'syncing' })
      try {
        await api.clockInOut(event.user_id, {
          client_event_id: event.client_event_id,
          event_type: event.event_type,
          occurred_at: event.occurred_at
        })
        await removeEvent(event)
      } catch (error) {
        await updateEvent(event, {
          status: 'failed',
          retry_count: (event.retry_count || 0) + 1,
          last_error: error?.message || 'Synchronisation impossible'
        })
        if (!error?.response || error.response.status >= 500) break
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
