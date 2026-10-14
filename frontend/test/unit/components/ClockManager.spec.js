import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import ClockManager from '@/components/ClockManager.vue'
import api from '@/services/api'
import { queueClockEvent, synchronisePendingEvents } from '@/services/syncService'
import { isOnline } from '@/services/networkService'
import { listPendingEvents, loadWorkingTimes, saveWorkingTimes } from '@/services/localDatabase'

vi.mock('@/services/api', () => ({
  default: {
    getWorkingTimes: vi.fn(),
    getUser: vi.fn(),
    clockInOut: vi.fn()
  }
}))

vi.mock('@/services/syncService', () => ({
  queueClockEvent: vi.fn(),
  synchronisePendingEvents: vi.fn()
}))

vi.mock('@/services/networkService', () => ({
  isOnline: vi.fn(() => true)
}))

vi.mock('@/utils/auth', () => ({
  readAuthUser: vi.fn(() => ({ id: 1, username: 'Joseph' }))
}))

vi.mock('@/services/localDatabase', async (importOriginal) => ({
  ...(await importOriginal()),
  listPendingEvents: vi.fn(),
  loadWorkingTimes: vi.fn(),
  saveWorkingTimes: vi.fn()
}))

function mountComponent() {
  return mount(ClockManager, {
    props: { userID: 1 },
    global: { stubs: { 'router-link': true } }
  })
}

describe('ClockManager.vue', () => {
  let pendingEvents

  beforeEach(() => {
    vi.clearAllMocks()
    pendingEvents = []
    isOnline.mockReturnValue(true)
    api.getWorkingTimes.mockResolvedValue({ data: { data: [] } })
    api.getUser.mockResolvedValue({ data: { data: { id: 1, username: 'Joseph' } } })
    listPendingEvents.mockImplementation(async () => pendingEvents)
    loadWorkingTimes.mockResolvedValue(null)
    saveWorkingTimes.mockResolvedValue(undefined)
    queueClockEvent.mockImplementation(async ({ userId, eventType, occurredAt }) => {
      const event = {
        client_event_id: 'offline-event-1',
        user_id: Number(userId),
        event_type: eventType,
        occurred_at: occurredAt
      }
      if (!isOnline()) pendingEvents.push(event)
      return event
    })
  })

  describe('load', () => {
    it('fetches working times on mount with the userID', async () => {
      mountComponent()
      await flushPromises()
      expect(api.getWorkingTimes).toHaveBeenCalledWith(1)
    })

    it('loads the user name for the header', async () => {
      mountComponent()
      await flushPromises()
      expect(api.getUser).toHaveBeenCalledWith(1)
    })

    it('falls back to auth user when the profile API fails', async () => {
      api.getUser.mockRejectedValue(new Error('boom'))
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.userName).toBe('Joseph')
    })
  })

  describe('status display', () => {
    it('shows "Au repos" when the latest session is closed', async () => {
      api.getWorkingTimes.mockResolvedValue({
        data: { data: [{ id: 1, start: '2026-09-22T09:00:00Z', end: '2026-09-22T17:00:00Z' }] }
      })
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.text()).toContain('Au repos')
    })

    it('shows "En cours" when a session is active', async () => {
      api.getWorkingTimes.mockResolvedValue({
        data: { data: [{ id: 1, start: '2026-09-22T09:00:00Z', end: null }] }
      })
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.text()).toContain('En cours')
    })

    it('shows the online badge when online', async () => {
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.isOnline).toBe(true)
      expect(wrapper.text()).toContain('En ligne')
    })
  })

  describe('clock in/out — online', () => {
    it('queues clock-in when currently clocked out', async () => {
      const wrapper = mountComponent()
      await flushPromises()
      await wrapper.vm.clock()

      expect(queueClockEvent).toHaveBeenCalledWith(
        expect.objectContaining({ userId: 1, eventType: 'clock_in' })
      )
    })

    it('queues clock-out when currently clocked in', async () => {
      api.getWorkingTimes.mockResolvedValue({
        data: { data: [{ id: 1, start: '2026-09-22T09:00:00Z', end: null }] }
      })
      const wrapper = mountComponent()
      await flushPromises()
      await wrapper.vm.clock()

      expect(queueClockEvent).toHaveBeenCalledWith(
        expect.objectContaining({ userId: 1, eventType: 'clock_out' })
      )
    })

    it('refreshes the session list after a successful clock', async () => {
      const wrapper = mountComponent()
      await flushPromises()
      const callsBefore = api.getWorkingTimes.mock.calls.length
      await wrapper.vm.clock()
      expect(api.getWorkingTimes.mock.calls.length).toBe(callsBefore + 1)
    })
  })

  describe('clock in/out — offline', () => {
    beforeEach(() => {
      isOnline.mockReturnValue(false)
      api.getWorkingTimes.mockRejectedValue(new Error('offline'))
      loadWorkingTimes.mockResolvedValue([])
    })

    it('queues the event and updates the local clock state', async () => {
      const wrapper = mountComponent()
      await flushPromises()
      await wrapper.vm.clock()

      expect(queueClockEvent).toHaveBeenCalledWith(
        expect.objectContaining({ userId: 1, eventType: 'clock_in' })
      )
      expect(api.clockInOut).not.toHaveBeenCalled()
      expect(wrapper.vm.clockIn).toBe(true)
      expect(wrapper.vm.correctionMessage).toContain('hors ligne')
    })

    it('uses the cached active session to queue clock-out', async () => {
      loadWorkingTimes.mockResolvedValue([
        { id: 22, start: '2026-09-22T09:00:00Z', end: null }
      ])
      const wrapper = mountComponent()
      await flushPromises()
      await wrapper.vm.clock()

      expect(queueClockEvent).toHaveBeenCalledWith(
        expect.objectContaining({ userId: 1, eventType: 'clock_out' })
      )
      expect(wrapper.vm.clockIn).toBe(false)
    })
  })

  describe('errors', () => {
    it('shows a generic message when the event cannot be saved locally', async () => {
      queueClockEvent.mockRejectedValue(new Error('storage failed'))
      const wrapper = mountComponent()
      await flushPromises()
      await wrapper.vm.clock()
      expect(wrapper.vm.errorMessage).toContain('n’a pas pu être enregistré sur cet appareil')
    })

    it('disables clocking when no server or local state is available', async () => {
      api.getWorkingTimes.mockRejectedValue(new Error('offline'))
      loadWorkingTimes.mockResolvedValue(null)
      isOnline.mockReturnValue(false)
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.clockStateKnown).toBe(false)
      expect(wrapper.find('.clock-button').attributes('disabled')).toBeDefined()
    })

    it('restores the active session from cache while offline', async () => {
      api.getWorkingTimes.mockRejectedValue(new Error('offline'))
      loadWorkingTimes.mockResolvedValue([
        { id: 22, start: '2026-09-22T09:00:00Z', end: null }
      ])
      isOnline.mockReturnValue(false)
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.clockIn).toBe(true)
      expect(wrapper.vm.clockStateKnown).toBe(true)
      expect(wrapper.text()).toContain('Historique hors ligne')
    })
  })

  describe('network events', () => {
    it('syncs pending events when coming back online', async () => {
      const wrapper = mountComponent()
      await flushPromises()
      wrapper.vm.onNetworkChange({ detail: { online: true } })
      expect(synchronisePendingEvents).toHaveBeenCalled()
    })

    it('updates isOnline when going offline', async () => {
      const wrapper = mountComponent()
      await flushPromises()
      wrapper.vm.onNetworkChange({ detail: { online: false } })
      expect(wrapper.vm.isOnline).toBe(false)
    })
  })
})
