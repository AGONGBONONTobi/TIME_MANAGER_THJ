import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import WorkingTime from '@/components/WorkingTime.vue'
import api from '@/services/api'

vi.mock('@/services/api', () => ({
  default: {
    getWorkingTime: vi.fn(),
    createWorkingTime: vi.fn(),
    updateWorkingTime: vi.fn(),
    deleteWorkingTime: vi.fn()
  }
}))

const mockRouter = { push: vi.fn() }

function mountComponent(props = {}) {
  return mount(WorkingTime, {
    props: { userID: 1, workingTimeID: null, ...props },
    global: { mocks: { $router: mockRouter } }
  })
}

describe('WorkingTime.vue', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('rendering', () => {
    it('shows "Créer une session" in create mode', () => {
      const wrapper = mountComponent()
      expect(wrapper.text()).toContain('Créer une session')
    })

    it('shows "Modifier une session" in edit mode', async () => {
      api.getWorkingTime.mockResolvedValue({
        data: { data: { id: 5, start: '2026-09-22T09:00:00Z', end: null } }
      })
      const wrapper = mountComponent({ workingTimeID: 5 })
      await wrapper.vm.$nextTick()
      expect(wrapper.text()).toContain('Modifier une session')
    })
  })

  describe('loading (edit mode)', () => {
    it('fetches the session on mount', async () => {
      api.getWorkingTime.mockResolvedValue({
        data: { data: { id: 5, start: '2026-09-22T09:00:00Z', end: '2026-09-22T17:00:00Z' } }
      })
      mountComponent({ workingTimeID: 5 })
      await vi.waitFor(() => expect(api.getWorkingTime).toHaveBeenCalledWith(1, 5))
    })

    it('shows error when fetch fails', async () => {
      api.getWorkingTime.mockRejectedValue(new Error('nope'))
      const wrapper = mountComponent({ workingTimeID: 5 })
      await vi.waitFor(() => {
        expect(wrapper.text()).toContain('Impossible de charger cette session')
      })
    })

    it('does not fetch on mount in create mode', () => {
      mountComponent()
      expect(api.getWorkingTime).not.toHaveBeenCalled()
    })
  })

  describe('payload keys', () => {
    it('sends start_at and end_at (NOT start/end)', async () => {
      api.createWorkingTime.mockResolvedValue({ data: { data: {} } })

      const wrapper = mountComponent()
      wrapper.vm.form.start = '2026-09-22T09:00'
      wrapper.vm.form.end = '2026-09-22T17:00'
      await wrapper.vm.submit()

      const [, payload] = api.createWorkingTime.mock.calls[0]
      expect(payload).toHaveProperty('start_at')
      expect(payload).toHaveProperty('end_at')
      expect(payload).not.toHaveProperty('start')
      expect(payload).not.toHaveProperty('end')
    })

    it('omits end_at when no end is provided', async () => {
      api.createWorkingTime.mockResolvedValue({ data: { data: {} } })

      const wrapper = mountComponent()
      wrapper.vm.form.start = '2026-09-22T09:00'
      wrapper.vm.form.end = ''
      await wrapper.vm.submit()

      const [, payload] = api.createWorkingTime.mock.calls[0]
      expect(payload).toHaveProperty('start_at')
      expect(payload).not.toHaveProperty('end_at')
    })
  })

  describe('submit — create mode', () => {
    it('calls createWorkingTime and redirects', async () => {
      api.createWorkingTime.mockResolvedValue({ data: { data: { id: 1 } } })

      const wrapper = mountComponent()
      wrapper.vm.form.start = '2026-09-22T09:00'
      await wrapper.vm.submit()

      expect(api.createWorkingTime).toHaveBeenCalled()
      expect(mockRouter.push).toHaveBeenCalledWith({
        name: 'workingTimes',
        params: { userID: 1 }
      })
    })

    it('shows error message when create fails', async () => {
      api.createWorkingTime.mockRejectedValue(new Error('fail'))

      const wrapper = mountComponent()
      wrapper.vm.form.start = '2026-09-22T09:00'
      await wrapper.vm.submit()

      expect(wrapper.vm.errorMessage).toContain('Impossible de créer')
    })
  })

  describe('submit — edit mode', () => {
    it('calls updateWorkingTime with the workingTimeID', async () => {
      api.getWorkingTime.mockResolvedValue({
        data: { data: { id: 5, start: '2026-09-22T09:00:00Z', end: null } }
      })
      api.updateWorkingTime.mockResolvedValue({ data: { data: {} } })

      const wrapper = mountComponent({ workingTimeID: 5 })
      await vi.waitFor(() => expect(api.getWorkingTime).toHaveBeenCalled())
      wrapper.vm.form.end = '2026-09-22T17:00'
      await wrapper.vm.submit()

      expect(api.updateWorkingTime).toHaveBeenCalledWith(5, expect.any(Object))
    })
  })

  describe('delete', () => {
    it('calls deleteWorkingTime when confirmed', async () => {
      vi.spyOn(window, 'confirm').mockReturnValue(true)
      api.getWorkingTime.mockResolvedValue({
        data: { data: { id: 5, start: '2026-09-22T09:00:00Z', end: null } }
      })
      api.deleteWorkingTime.mockResolvedValue({})

      const wrapper = mountComponent({ workingTimeID: 5 })
      await vi.waitFor(() => expect(api.getWorkingTime).toHaveBeenCalled())
      await wrapper.vm.deleteWorkingTime()

      expect(api.deleteWorkingTime).toHaveBeenCalledWith(5)
      expect(mockRouter.push).toHaveBeenCalled()
    })

    it('does nothing when the user cancels', async () => {
      vi.spyOn(window, 'confirm').mockReturnValue(false)
      api.getWorkingTime.mockResolvedValue({
        data: { data: { id: 5, start: '2026-09-22T09:00:00Z', end: null } }
      })

      const wrapper = mountComponent({ workingTimeID: 5 })
      await vi.waitFor(() => expect(api.getWorkingTime).toHaveBeenCalled())
      await wrapper.vm.deleteWorkingTime()

      expect(api.deleteWorkingTime).not.toHaveBeenCalled()
    })
  })
})
