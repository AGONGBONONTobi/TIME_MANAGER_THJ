import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import WorkingTimes from '@/components/WorkingTimes.vue'
import api from '@/services/api'

vi.mock('@/services/api', () => ({
  default: { getWorkingTimes: vi.fn() }
}))

const global = {
  mocks: { $route: { params: { userID: '1' } } }
}

function mountComponent() {
  return mount(WorkingTimes, { global })
}

describe('WorkingTimes.vue', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
  })

  it('fetches on mount with route userID', async () => {
    api.getWorkingTimes.mockResolvedValue({ data: { data: [] } })
    mountComponent()
    await vi.waitFor(() => expect(api.getWorkingTimes).toHaveBeenCalledWith('1'))
  })

  it('sorts sessions newest first', async () => {
    api.getWorkingTimes.mockResolvedValue({
      data: {
        data: [
          { id: 1, start: '2026-09-20T09:00:00Z', end: '2026-09-20T17:00:00Z' },
          { id: 2, start: '2026-09-22T09:00:00Z', end: null }
        ]
      }
    })
    const wrapper = mountComponent()
    await vi.waitFor(() => expect(wrapper.vm.sortedWorkingTimes.length).toBe(2))
    expect(wrapper.vm.sortedWorkingTimes[0].id).toBe(2)
  })

  it('computes total duration across sessions', async () => {
    api.getWorkingTimes.mockResolvedValue({
      data: {
        data: [
          { id: 1, start: '2026-09-20T09:00:00Z', end: '2026-09-20T17:00:00Z' }, // 8h
          { id: 2, start: '2026-09-21T09:00:00Z', end: '2026-09-21T10:30:00Z' }  // 1.5h
        ]
      }
    })
    const wrapper = mountComponent()
    await vi.waitFor(() => expect(wrapper.vm.totalDuration).toBe('9h 30m'))
  })

  it('detects an active session', async () => {
    api.getWorkingTimes.mockResolvedValue({
      data: { data: [{ id: 1, start: '2026-09-22T09:00:00Z', end: null }] }
    })
    const wrapper = mountComponent()
    await vi.waitFor(() => expect(wrapper.vm.hasActiveSession).toBe(true))
  })

  it('shows error message on failure', async () => {
    api.getWorkingTimes.mockRejectedValue(new Error('boom'))
    const wrapper = mountComponent()
    await vi.waitFor(() => {
      expect(wrapper.text()).toContain('Impossible de charger')
    })
  })
})
