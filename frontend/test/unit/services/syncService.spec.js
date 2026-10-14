import { beforeEach, describe, expect, it, vi } from 'vitest'
import api from '@/services/api'
import { enqueueEvent, listPendingEvents, removeEvent, updateEvent } from '@/services/localDatabase'
import { isOnline } from '@/services/networkService'
import { queueClockEvent, synchronisePendingEvents } from '@/services/syncService'

vi.mock('@/services/api', () => ({
  default: { clockInOut: vi.fn() }
}))

vi.mock('@/services/localDatabase', () => ({
  enqueueEvent: vi.fn(),
  listPendingEvents: vi.fn(),
  removeEvent: vi.fn(),
  updateEvent: vi.fn()
}))

vi.mock('@/services/networkService', () => ({
  isOnline: vi.fn(() => false)
}))

vi.mock('@/services/nativeFeatures', () => ({
  notifySync: vi.fn()
}))

vi.mock('@/utils/auth', () => ({
  readAuthUser: vi.fn(() => ({ id: 7 }))
}))

describe('syncService', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    isOnline.mockReturnValue(false)
    enqueueEvent.mockResolvedValue(undefined)
    listPendingEvents.mockResolvedValue([])
    removeEvent.mockResolvedValue(undefined)
    updateEvent.mockResolvedValue(undefined)
  })

  it('persists an offline dashboard clock action without calling the API', async () => {
    const event = await queueClockEvent({
      userId: 7,
      eventType: 'clock_in',
      occurredAt: '2026-10-14T08:00:00.000Z'
    })

    expect(event).toMatchObject({
      user_id: 7,
      event_type: 'clock_in',
      occurred_at: '2026-10-14T08:00:00.000Z'
    })
    expect(enqueueEvent).toHaveBeenCalledWith(event)
    expect(api.clockInOut).not.toHaveBeenCalled()
  })

  it('replays queued events with the original idempotency key after reconnection', async () => {
    const event = {
      client_event_id: 'persisted-event-1',
      user_id: 7,
      event_type: 'clock_in',
      occurred_at: '2026-10-14T08:00:00.000Z',
      status: 'pending',
      retry_count: 0
    }
    isOnline.mockReturnValue(true)
    listPendingEvents.mockResolvedValue([event])
    api.clockInOut.mockResolvedValue({ data: {} })

    await synchronisePendingEvents()

    expect(api.clockInOut).toHaveBeenCalledWith(7, {
      client_event_id: 'persisted-event-1',
      event_type: 'clock_in',
      occurred_at: '2026-10-14T08:00:00.000Z'
    })
    expect(removeEvent).toHaveBeenCalledWith(event)
  })

  it('retains an event and records a retry when synchronization fails', async () => {
    const event = {
      client_event_id: 'persisted-event-2',
      user_id: 7,
      event_type: 'clock_out',
      occurred_at: '2026-10-14T17:00:00.000Z',
      status: 'pending',
      retry_count: 1
    }
    isOnline.mockReturnValue(true)
    listPendingEvents.mockResolvedValue([event])
    api.clockInOut.mockRejectedValue(new Error('network unavailable'))

    await synchronisePendingEvents()

    expect(updateEvent).toHaveBeenCalledWith(event, expect.objectContaining({
      status: 'failed',
      retry_count: 2
    }))
    expect(removeEvent).not.toHaveBeenCalled()
  })

  it('does not send another account’s pending clock events', async () => {
    isOnline.mockReturnValue(true)
    listPendingEvents.mockResolvedValue([{
      client_event_id: 'other-account-event',
      user_id: 8,
      event_type: 'clock_in',
      occurred_at: '2026-10-14T08:00:00.000Z'
    }])

    await synchronisePendingEvents()

    expect(api.clockInOut).not.toHaveBeenCalled()
    expect(removeEvent).not.toHaveBeenCalled()
  })

  it('drains new events queued while another event is synchronizing', async () => {
    const firstEvent = {
      client_event_id: 'event-in-progress',
      user_id: 7,
      event_type: 'clock_in',
      occurred_at: '2026-10-14T08:00:00.000Z',
      status: 'pending',
      retry_count: 0
    }
    const secondEvent = {
      client_event_id: 'queued-during-sync',
      user_id: 7,
      event_type: 'clock_out',
      occurred_at: '2026-10-14T17:00:00.000Z',
      status: 'pending',
      retry_count: 0
    }
    let pending = [firstEvent]
    let finishFirstRequest
    isOnline.mockReturnValue(true)
    listPendingEvents.mockImplementation(async () => pending)
    api.clockInOut.mockImplementation(async (_userId, payload) => {
      if (payload.client_event_id === firstEvent.client_event_id) {
        await new Promise((resolve) => { finishFirstRequest = resolve })
      }
    })
    removeEvent.mockImplementation(async (event) => {
      pending = pending.filter((item) => item.client_event_id !== event.client_event_id)
    })

    const firstSync = synchronisePendingEvents()
    await vi.waitFor(() => expect(api.clockInOut).toHaveBeenCalledWith(7, expect.objectContaining({
      client_event_id: firstEvent.client_event_id
    })))
    pending.push(secondEvent)
    await synchronisePendingEvents()
    finishFirstRequest()
    await firstSync

    expect(api.clockInOut).toHaveBeenCalledTimes(2)
    expect(api.clockInOut).toHaveBeenLastCalledWith(7, expect.objectContaining({
      client_event_id: secondEvent.client_event_id
    }))
    expect(removeEvent).toHaveBeenCalledWith(secondEvent)
  })
})
