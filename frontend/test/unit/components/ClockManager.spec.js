import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import ClockManager from '@/components/ClockManager.vue'
import api from '@/services/api'
import { queueClockEvent, synchronisePendingEvents } from '@/services/syncService'
import { isOnline } from '@/services/networkService'

vi.mock('@/services/api', () => ({
  default: {
    getClocks: vi.fn(),
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

function mountComponent() {
  return mount(ClockManager, {
    props: { userID: 1 },
    global: { stubs: { 'router-link': true } }
  })
}

describe('ClockManager.vue', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    isOnline.mockReturnValue(true)
    api.getClocks.mockResolvedValue({ data: { data: [] } })
    api.getUser.mockResolvedValue({ data: { data: { id: 1, username: 'Joseph' } } })
  })

  describe('load', () => {
    it('fetches clocks on mount with the userID', async () => {
      mountComponent()
      await flushPromises()
      expect(api.getClocks).toHaveBeenCalledWith(1)
    })

    it('loads the user name for the header', async () => {
      mountComponent()
      await flushPromises()
      expect(api.getUser).toHaveBeenCalledWith(1)
    })

    it('falls back to auth user when the API fails', async () => {
      api.getUser.mockRejectedValue(new Error('boom'))
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.userName).toBe('Joseph')
    })
  })

  describe('status display', () => {
    it('shows "Au repos" when latest clock status is false', async () => {
      api.getClocks.mockResolvedValue({
        data: { data: [{ id: 1, status: false, time: '2026-09-22T17:00:00Z' }] }
      })
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.text()).toContain('Au repos')
    })

    it('shows "En cours" when latest clock status is true', async () => {
      api.getClocks.mockResolvedValue({
        data: { data: [{ id: 1, status: true, time: '2026-09-22T09:00:00Z' }] }
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
    it('sends event_type=clock_in when currently clocked out', async () => {
      api.clockInOut.mockResolvedValue({ data: {} })
      const wrapper = mountComponent()
      await flushPromises()
      await wrapper.vm.clock()

      expect(api.clockInOut).toHaveBeenCalledWith(
        1,
        expect.objectContaining({ event_type: 'clock_in', occurred_at: expect.any(String) })
      )
    })

    it('sends event_type=clock_out when currently clocked in', async () => {
      api.getClocks.mockResolvedValue({
        data: { data: [{ id: 1, status: true, time: '2026-09-22T09:00:00Z' }] }
      })
      api.clockInOut.mockResolvedValue({ data: {} })
      const wrapper = mountComponent()
      await flushPromises()
      await wrapper.vm.clock()

      expect(api.clockInOut).toHaveBeenCalledWith(
        1,
        expect.objectContaining({ event_type: 'clock_out' })
      )
    })

    it('refreshes the clocks list after a successful clock', async () => {
      api.clockInOut.mockResolvedValue({ data: {} })
      const wrapper = mountComponent()
      await flushPromises()
      const callsBefore = api.getClocks.mock.calls.length
      await wrapper.vm.clock()
      expect(api.getClocks.mock.calls.length).toBe(callsBefore + 1)
    })

    it('does not queue an event when online', async () => {
      api.clockInOut.mockResolvedValue({ data: {} })
      const wrapper = mountComponent()
      await flushPromises()
      await wrapper.vm.clock()
      expect(queueClockEvent).not.toHaveBeenCalled()
    })
  })

  describe('clock in/out — offline', () => {
    beforeEach(() => {
      isOnline.mockReturnValue(false)
    })

    it('queues the event instead of calling the API', async () => {
      const wrapper = mountComponent()
      await flushPromises()
      await wrapper.vm.clock()

      expect(queueClockEvent).toHaveBeenCalledWith(
        expect.objectContaining({ userId: 1, eventType: 'clock_in' })
      )
      expect(api.clockInOut).not.toHaveBeenCalled()
    })

    it('flips the local clock state so the button becomes Clock Out', async () => {
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.clockIn).toBe(false)
      await wrapper.vm.clock()
      expect(wrapper.vm.clockIn).toBe(true)
    })

    it('shows the offline confirmation message', async () => {
      const wrapper = mountComponent()
      await flushPromises()
      await wrapper.vm.clock()
      expect(wrapper.vm.errorMessage).toContain('hors ligne')
    })
  })

  describe('errors', () => {
    it('shows "Une session est déjà en cours" on 409', async () => {
      api.clockInOut.mockRejectedValue({
        response: { data: { error: 'already clocked in' } }
      })
      const wrapper = mountComponent()
      await flushPromises()
      await wrapper.vm.clock()
      expect(wrapper.vm.errorMessage).toBe('Une session est déjà en cours.')
    })

    it('shows a generic message on other failures', async () => {
      api.clockInOut.mockRejectedValue(new Error('boom'))
      const wrapper = mountComponent()
      await flushPromises()
      await wrapper.vm.clock()
      expect(wrapper.vm.errorMessage).toContain('n’a pas pu être enregistré')
    })

    it('shows a load error when fetching clocks fails', async () => {
      api.getClocks.mockRejectedValue(new Error('boom'))
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.errorMessage).toBe('Impossible de charger les pointages.')
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
