import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import ClockManager from '@/components/ClockManager.vue'
import api from '@/services/api'

vi.mock('@/services/api', () => ({
  default: {
    getClocks: vi.fn(),
    clockInOut: vi.fn()
  }
}))

function mountComponent() {
  return mount(ClockManager, {
    props: { userID: 1 },
    global: { mocks: { $router: { push: vi.fn() } } }
  })
}

describe('ClockManager.vue', () => {
  beforeEach(() => vi.clearAllMocks())

  it('fetches clocks on mount', async () => {
    api.getClocks.mockResolvedValue({ data: { data: [] } })
    mountComponent()
    await vi.waitFor(() => expect(api.getClocks).toHaveBeenCalledWith(1))
  })

  it('shows "Au repos" when latest clock status is false', async () => {
    api.getClocks.mockResolvedValue({
      data: { data: [{ id: 1, status: false, time: '2026-09-22T17:00:00Z' }] }
    })
    const wrapper = mountComponent()
    await vi.waitFor(() => expect(wrapper.text()).toContain('Au repos'))
  })

  it('shows "En cours" when latest clock status is true', async () => {
    api.getClocks.mockResolvedValue({
      data: { data: [{ id: 1, status: true, time: '2026-09-22T09:00:00Z' }] }
    })
    const wrapper = mountComponent()
    await vi.waitFor(() => expect(wrapper.text()).toContain('En cours'))
  })

  it('calls clockInOut and refreshes on clock', async () => {
    api.getClocks.mockResolvedValue({ data: { data: [] } })
    api.clockInOut.mockResolvedValue({ data: {} })

    const wrapper = mountComponent()
    await vi.waitFor(() => expect(api.getClocks).toHaveBeenCalledTimes(1))
    await wrapper.vm.clock()

    expect(api.clockInOut).toHaveBeenCalledWith(1)
    expect(api.getClocks).toHaveBeenCalledTimes(2)
  })

  it('shows "Une session est déjà en cours" on 409', async () => {
    api.getClocks.mockResolvedValue({ data: { data: [] } })
    api.clockInOut.mockRejectedValue({
      response: { data: { error: 'already clocked in' } }
    })

    const wrapper = mountComponent()
    await vi.waitFor(() => expect(api.getClocks).toHaveBeenCalled())
    await wrapper.vm.clock()

    expect(wrapper.vm.errorMessage).toBe('Une session est déjà en cours.')
  })

  it('shows generic error on other failures', async () => {
    api.getClocks.mockResolvedValue({ data: { data: [] } })
    api.clockInOut.mockRejectedValue(new Error('boom'))

    const wrapper = mountComponent()
    await vi.waitFor(() => expect(api.getClocks).toHaveBeenCalled())
    await wrapper.vm.clock()

    expect(wrapper.vm.errorMessage).toContain('n’a pas pu être enregistré')
  })
})
